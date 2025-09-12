defmodule PrintClient.Printer.Discovery do
  @moduledoc """
  Discovers potential usb and serial printers connected to the system.
  """
  require Logger

  alias PrintClient.Settings
  alias Circuits.UART
  alias PrintClient.Printer
  alias PrintClient.Printer.Adapter.{MockPrinter, NetworkPrinter, SerialPrinter, UsbPrinter}

  @default_baud_rate 9600

  @pubsub PrintClient.PubSub
  @topic "printers:discovery"

  # --- GenServer Implementation ---

  use GenServer

  @impl true
  def init(opts) do
    state = %{
      printers: [],
      last_scan: Time.utc_now(),
      scan_interval: Keyword.get(opts, :scan_interval, 1_000)
    }

    Process.send_after(self(), :scan, state.scan_interval)

    {:ok, state}
  end

  @spec start_link(map()) :: GenServer.start_link()
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def handle_info(:scan, state) do
    discovered = discover_all_printers()
    state.printers

    # Notify of printers added
    difference(discovered, state.printers)
    |> Enum.each(&notify(:added, &1))

    # Notify of printers removed
    difference(state.printers, discovered)
    |> Enum.each(&notify(:removed, &1))

    new_state =
      state
      |> Map.put(:printers, discovered)
      |> Map.put(:last_scan, Time.utc_now())

    Process.send_after(self(), :scan, state.scan_interval)

    {:noreply, new_state}
  end

  # --- Discovery API ---

  @doc """
  Subscribes to discovery events.
  """
  @spec subscribe :: :ok
  def subscribe do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  @doc """
  Lists all available printers.
  """
  @spec discover_all_printers() :: [Printer.t()] | []
  def discover_all_printers do
    [
      maybe_load_mock_printer(),
      load_saved_printers(),
      discover_serial_printers(),
      discover_usb_printers(),
      #discover_network_printers()
    ]
    |> Enum.concat()
  end

  @doc """
  Returns configured network printers.
  """
  @spec load_saved_printers() :: [Printer.t()] | []
  def load_saved_printers do
    Settings.all_printers()
    |> Enum.map(fn printer ->
      {adapter, config} = case printer.type do
        :network -> {NetworkPrinter, %{ip: printer.hostname, port: printer.port}}
        :usb -> {UsbPrinter, %{vendor: printer.vendor_id, product: printer.product_id}}
        :serial -> {SerialPrinter, %{path: printer.serial_port, speed: @default_baud_rate}}
      end

      %Printer{
        printer_id: format_id_string(printer.name |> String.downcase()),
        encoding: printer.encoding,
        name: printer.name,
        type: printer.type,
        adapter_module: adapter,
        adapter_config: config
      }
    end)
  end

  @doc """
  Discovers potential usb printers.
  """
  @spec discover_usb_printers() :: [Printer.t()] | []
  def discover_usb_printers do
    :usb.get_device_list()
    |> case do
      {:ok, devices} ->
        devices |> Enum.map(&format_discovered_usb/1)

      {:error, reason} ->
        Logger.warning("Printer.Discovery: Failed to discover usb printers. #{inspect(reason)}")
        []
    end
  end

  @doc """
  Discovers potential serial printers.
  """
  @spec discover_serial_printers() :: [Printer.t()] | []
  def discover_serial_printers do
    UART.enumerate()
    |> Enum.map(fn {port, info} ->
      Logger.info("Discovered serial port: #{inspect(info)}")
      format_discovered_port(port)
    end)
  end

  # --- Internal API ---

  defp format_discovered_usb(device) do
    {:ok, %{vendor_id: vendor, product_id: product}} = :usb.get_device_descriptor(device)

    usb_vendors_map = load_usb_vendor_ids()

    %Printer{
      printer_id: id_of_port("usb_#{vendor}:#{product}"),
      encoding: :tspl,
      name: "USB #{usb_vendors_map[vendor]} #{vendor}:#{product}",
      type: :usb,
      adapter_module: UsbPrinter,
      adapter_config: %{vendor: vendor, product: product}
    }
  end

  defp format_discovered_port(port),
    do: %Printer{
      printer_id: id_of_port(port),
      encoding: :tspl,
      name: "#{port}",
      type: :serial,
      adapter_module: SerialPrinter,
      adapter_config: %{path: port, speed: @default_baud_rate}
    }

  defp id_of_port(port_name) do
    {:ok, hostname} = :inet.gethostname()

    formatted_hostname =
      hostname
      |> to_string()
      |> format_id_string()

    formatted_port_name = format_id_string(port_name)

    "#{formatted_hostname}_#{formatted_port_name}"
  end

  defp id_of_network_printer(network_printer) do
    formatted_hostname = format_id_string(network_printer.hostname)
    formatted_port = format_id_string(network_printer.port)
    "#{formatted_hostname}_#{formatted_port}"
  end

  defp format_id_string(id) when not is_binary(id), do: id |> to_string |> format_id_string
  defp format_id_string(id_string), do: String.replace(id_string, ~r"[^A-z0-9-_]", "_")

  # Hacky way to load in USB vendor IDs
  defp load_usb_vendor_ids do
    with priv_dir <- Application.app_dir(:print_client, "priv/static/"),
         usb_id_path <- Path.join(priv_dir, "./usb-ids.tsv"),
         true <- File.exists?(usb_id_path),
         stream <- File.stream!(usb_id_path, :line, [:utf8]),
         usb_id_map <- CSV.decode(stream, separator: ?\t, headers: true) do
      Enum.reduce(usb_id_map, %{}, fn info, acc ->
        case info do
          {:ok, %{"Id" => id, "Manufacturer" => manufacturer}} ->
            {id, _} = Integer.parse(id, 16)
            Map.put(acc, id, manufacturer)

          _ ->
            acc
        end
      end)
    else
      {:error, reason} ->
        Logger.warning(
          "Printer.Discovery: failed to load usb vendor id map. Does the file exist? #{inspect(reason)}"
        )

        %{}
    end
  end

  defp maybe_load_mock_printer do
    include_mocks =
      Application.get_env(:print_client, PrintClient.Printer.Discovery, %{include_mocks: false})[
        :include_mocks
      ]

    if include_mocks do
      [
        %Printer{
          printer_id: "mock_1",
          encoding: :tspl,
          name: "Mock 1",
          type: :mock,
          adapter_module: MockPrinter,
          adapter_config: %{name: "1"}
        },
        %Printer{
          printer_id: "mock_2",
          encoding: :tspl,
          name: "Mock 2",
          type: :mock,
          adapter_module: MockPrinter,
          adapter_config: %{name: "2"}
        }
      ]
    else
      []
    end
  end

  defp difference(list_a, list_b), do: MapSet.difference(MapSet.new(list_a), MapSet.new(list_b))

  defp notify(state, printer),
    do: Phoenix.PubSub.broadcast_from(@pubsub, self(), @topic, {state, printer})
end
