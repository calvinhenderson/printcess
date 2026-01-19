defmodule PrintClient.Printer.Adapter.MockPrinter do
  @behaviour PrintClient.Printer.Adapter

  alias PrintClient.Printer

  require Logger

  # Default settings, can be overridden
  defstruct name: nil,
            connected?: false,
            online?: false

  @type t :: %__MODULE__{
          name: String.t() | nil,
          connected?: boolean(),
          online?: boolean()
        }

  @impl Printer.Adapter
  def connect(%__MODULE__{name: name, connected?: false} = adapter_state) do
    Logger.info("MockPrinter #{name}: creating mock printer #{inspect(adapter_state)}")

    {:ok, %{adapter_state | connected?: true}}
  end

  def connect(%__MODULE__{name: name, connected?: _} = adapter_state) do
    # Already connected or has a reference, treat as connected for simplicity or re-verify
    Logger.info("MockPrinter #{name}: connection attempt when already connected.")
    {:ok, adapter_state}
  end

  @impl Printer.Adapter
  def print(%__MODULE__{name: name, connected?: false}, _data) do
    Logger.error("MockPrinter #{name}: cannot print, mock is not connected.")
    {:error, :not_connected}
  end

  def print(%__MODULE__{connected?: _} = _adapter_state, _data), do: :ok

  @impl Printer.Adapter
  def disconnect(%__MODULE__{connected?: false} = adapter_state), do: {:ok, adapter_state}

  def disconnect(%__MODULE__{name: name} = adapter_state) do
    Logger.info("MockPrinter #{name}: closing mock.")
    # Circuits.UART.close will stop the UART GenServer
    {:ok, %{adapter_state | connected?: false}}
  end

  @impl Printer.Adapter
  def status(%__MODULE__{connected?: false}) do
    :disconnected
  end

  def status(%__MODULE__{connected?: _}), do: :connected

  @impl Printer.Adapter
  def online?(%__MODULE__{online?: state}), do: state.online?
end
