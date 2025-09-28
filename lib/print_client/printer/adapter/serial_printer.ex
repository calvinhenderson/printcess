defmodule PrintClient.Printer.Adapter.SerialPrinter do
  @behaviour PrintClient.Printer.Adapter

  alias PrintClient.Printer

  require Logger

  # Default settings, can be overridden
  defstruct port: nil,
            vendor: nil,
            serial_number: nil,
            # Will store the pid of the Circuits.UART process
            uart_ref: nil,
            speed: 9600,
            data_bits: 8,
            stop_bits: 1,
            parity: :none,
            flow_control: :none

  @type t :: %__MODULE__{
          port: String.t(),
          uart_ref: pid() | nil,
          speed: pos_integer(),
          data_bits: 5..8,
          stop_bits: 1..2,
          # :mark and :space might be OS dependent
          parity: :none | :even | :odd | :mark | :space,
          # hardware/software flow control
          flow_control: :none | :rtscts | :xonxoff
        }

  @impl Printer.Adapter
  def connect(%__MODULE__{port: port, uart_ref: nil} = adapter_state) do
    opts = [
      speed: adapter_state.speed,
      data_bits: adapter_state.data_bits,
      stop_bits: adapter_state.stop_bits,
      parity: adapter_state.parity,
      # We'll manage reads/writes explicitly
      active: false,
      flow_control: adapter_state.flow_control
    ]

    Logger.info("SerialPrinter: Attempting to open UART #{port} with opts: #{inspect(opts)}")

    case Circuits.UART.open(port, opts) do
      {:ok, uart_pid} ->
        Logger.info("SerialPrinter: UART #{port} opened successfully. PID: #{inspect(uart_pid)}")
        # Store the UART process reference. We need to monitor it.
        {:ok, %{adapter_state | uart_ref: uart_pid}}

      {:error, reason} ->
        Logger.error("SerialPrinter: Failed to open UART #{port} - #{inspect(reason)}")
        {:error, reason}
    end
  end

  def connect(%__MODULE__{uart_ref: _pid} = adapter_state) do
    # Already connected or has a reference, treat as connected for simplicity or re-verify
    Logger.info("SerialPrinter: UART #{adapter_state.port} connection attempt on existing ref.")
    {:ok, adapter_state}
  end

  @impl Printer.Adapter
  def print(%__MODULE__{uart_ref: nil}, _data) do
    Logger.error("SerialPrinter: Cannot print, UART is not open.")
    {:error, :not_connected}
  end

  def print(%__MODULE__{uart_ref: uart_pid, port: port} = _adapter_state, data) do
    # Ensure the uart_pid is alive before writing.
    if Process.alive?(uart_pid) do
      case Circuits.UART.write(uart_pid, data) do
        :ok ->
          # For some serial printers, a flush might be needed or a small delay.
          # Circuits.UART.flush(uart_pid, :output)
          :ok

        {:error, reason} ->
          Logger.error("SerialPrinter: Failed to write to UART #{port} - #{inspect(reason)}")
          # The GenServer using this adapter should handle this.
          {:error, reason}
      end
    else
      Logger.error("SerialPrinter: Cannot print, UART process for #{port} is not alive.")
      {:error, :not_connected_process_dead}
    end
  end

  @impl Printer.Adapter
  def disconnect(%__MODULE__{uart_ref: nil} = adapter_state) do
    # Already disconnected
    {:ok, adapter_state}
  end

  def disconnect(%__MODULE__{uart_ref: uart_pid, port: port} = adapter_state) do
    Logger.info("SerialPrinter: Closing UART #{port}, PID: #{inspect(uart_pid)}")
    # Circuits.UART.close will stop the UART GenServer
    Circuits.UART.close(uart_pid)
    {:ok, %{adapter_state | uart_ref: nil}}
  end

  @impl Printer.Adapter
  def status(%__MODULE__{uart_ref: nil}) do
    {:ok, :disconnected}
  end

  def status(%__MODULE__{uart_ref: uart_pid, port: port}) do
    if Process.alive?(uart_pid) do
      # Further checks could involve trying to get port settings, etc.
      # For now, if the process is alive, we assume it's "connected".
      :connected
    else
      Logger.warning("SerialPrinter: UART process for #{port} is not alive.")
      :disconnected
    end
  end

  @impl Printer.Adapter
  def online?(%__MODULE__{} = adapter_state) do
    status(adapter_state)
    |> case do
      :connected ->
        true

      :disconnected ->
        connect(adapter_state)
        |> case do
          {:ok, connected_state} ->
            disconnect(connected_state)
            true

          _ ->
            false
        end
    end
  end
end
