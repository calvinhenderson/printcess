# lib/printer/adapter/network_printer.ex
defmodule PrintClient.Printer.Adapter.NetworkPrinter do
  @moduledoc """
  Implements the Printer.Adapter behavior for IP-based printers.
  """

  @behaviour PrintClient.Printer.Adapter
  alias PrintClient.Printer

  require Logger

  defstruct ip: nil, port: nil, socket: nil, connect_timeout: 5000

  @type t :: %__MODULE__{
          ip: :inet.hostname() | :inet.ip_address(),
          port: :inet.port_number(),
          socket: :gen_tcp.socket() | nil,
          connect_timeout: timeout()
        }

  @impl Printer.Adapter
  def connect(%__MODULE__{ip: ip, port: port, connect_timeout: timeout} = adapter_state) do
    Logger.info("NetworkPrinter: Attempting to connect to #{ip}:#{port}")

    # Ensure any previous socket is closed before attempting a new connection
    if adapter_state.socket, do: :gen_tcp.close(adapter_state.socket)

    case :gen_tcp.connect(to_charlist(ip), port, [:binary, active: false], timeout) do
      {:ok, socket} ->
        Logger.info("NetworkPrinter: Connected to #{ip}:#{port}")
        {:ok, %{adapter_state | socket: socket}}

      {:error, reason} ->
        Logger.error("NetworkPrinter: Failed to connect to #{ip}:#{port} - #{inspect(reason)}")
        {:error, reason, adapter_state}
    end
  end

  @impl Printer.Adapter
  def print(%__MODULE__{socket: nil} = adapter_state, _data) do
    Logger.error("NetworkPrinter: Cannot print, socket is not connected.")
    {:disconnected, adapter_state}
  end

  def print(%__MODULE__{socket: socket} = adapter_state, data) do
    case :gen_tcp.send(socket, data) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("NetworkPrinter: Failed to send data - #{inspect(reason)}")
        # Close the socket on send error
        {:ok, adapter_state} = disconnect(adapter_state)
        {:error, reason, adapter_state}
    end
  end

  @impl Printer.Adapter
  def disconnect(%__MODULE__{socket: nil} = adapter_state) do
    # Already disconnected or not connected
    {:ok, adapter_state}
  end

  def disconnect(%__MODULE__{socket: socket} = adapter_state) do
    :gen_tcp.close(socket)
    Logger.info("NetworkPrinter: Disconnected from #{adapter_state.ip}:#{adapter_state.port}")
    {:ok, %{adapter_state | socket: nil}}
  end

  @impl Printer.Adapter
  def status(%__MODULE__{socket: nil}) do
    :disconnected
  end

  def status(%__MODULE__{socket: socket}) when not is_nil(socket) do
    :connected
  end

  @impl Printer.Adapter
  def online?(%__MODULE__{socket: socket}) when not is_nil(socket), do: true

  def online?(adapter_state) do
    connect(adapter_state)
    |> case do
      {:ok, %{socket: socket} = connected_state} when not is_nil(socket) ->
        disconnect(connected_state)
        true

      _ ->
        false
    end
  end

  defmodule Schema do
    use Ecto.Schema

    import Ecto.Changeset

    schema "printer" do
      field :name, :string
      field :hostname, :string
      field :port, :integer, default: 9100
    end

    def changeset(printer, attrs) do
      printer
      |> cast(attrs, [:name, :hostname, :port, :sort])
      |> validate_required([:name, :hostname])
      |> validate_number(:sort, min: 0)
    end
  end
end
