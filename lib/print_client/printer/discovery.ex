defmodule PrintClient.Printer.Discovery do
  @moduledoc """
  Discovers potential usb and serial printers connected to the system.
  """
  require Logger

  alias PrintClient.Settings
  alias Circuits.UART
  alias PrintClient.Printer
  alias PrintClient.Printer.Adapter.{NetworkPrinter, SerialPrinter, UsbPrinter}

  use GenServer

  @default_baud_rate 9600

  @doc """
  Lists all available printers.
  """
  @spec discover_all_printers() :: [Printer.t()] | []
  def discover_all_printers do
    [
      discover_serial_printers(),
      discover_usb_printers(),
      discover_network_printers()
    ]
    |> Enum.concat()
  end

  @doc """
  Returns configured network printers.
  """
  @spec discover_network_printers() :: [Printer.t()] | []
  def discover_network_printers do
    Settings.all_printers()
    |> Enum.map(fn network_printer ->
      {network_printer.name,
       %Printer{
         printer_id: id_of_network_printer(network_printer),
         name: network_printer.name,
         type: :network,
         adapter_module: Printer.Adapter.NetworkPrinter,
         adapter_config: network_printer
       }}
    end)
  end

  @doc """
  Discovers potential usb printers.
  """
  @spec discover_usb_printers() :: [Printer.t()] | []
  def discover_usb_printers do
    usb_vendors_map = load_usb_vendor_ids()

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
      name: "USB #{usb_vendors_map[vendor]} #{vendor}:#{product}",
      type: :usb,
      adapter_module: UsbPrinter,
      adapter_config: %{vendor: vendor, product: product}
    }
  end

  defp format_discovered_port(port),
    do: %Printer{
      printer_id: id_of_port(port),
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
end
