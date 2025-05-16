defmodule PrintClient.Printer do
  @moduledoc """
  Interfaces with label printers through the use of protocols and adapters.
  """

  use GenServer, restart: :transient

  require Logger

  alias PrintClient.Printer.{Adapter, PrintJob, Registry}

  defstruct printer_id: nil,
            name: nil,
            type: nil,
            adapter_module: nil,
            adapter_config: nil,
            adapter_state: nil,
            job_queue: nil,
            prev_job_id: 0,
            connected?: false,
            connect_retry_timer: nil,
            connect_retry_delay_ms: 1000,
            connect_retries: 0,
            connect_max_retries: 5,
            connection_monitor_ref: nil,
            stop: false

  @type t :: [
          printer_id: term(),
          name: :string | nil,
          type: :network | :serial | :usb | nil,
          adapter_module: Module.t() | nil,
          adapter_config: Map.t() | nil,
          adapter_state: term(),
          job_queue: :queue.new(),
          prev_job_id: number(),
          connected?: boolean(),
          connect_retry_timer: :timer.start_link() | nil,
          connect_retry_delay_ms: number(),
          connect_retries: number(),
          connect_max_retries: number(),
          connection_monitor_ref: Process.monitor() | nil,
          stop: boolean()
        ]

  @pubsub PrintClient.PubSub

  # --- Client API ---

  @spec start_link(map()) :: GenServer.start_link()
  def start_link(opts) do
    dbg(opts)
    printer_id = Map.fetch!(opts, :printer_id)
    GenServer.start_link(__MODULE__, opts, name: Registry.via_tuple(printer_id))
  end

  @doc "Opens a connection to the physical printer."
  def connect(printer_id), do: GenServer.call(printer_id, :connect)

  @doc "Closes a connection to the physical printer."
  def disconnect(printer_id), do: GenServer.call(printer_id, :disconnect)

  @doc """
  Adds a new job to the printer's queue.

  The job will be dispatched as soon as the printer becomes available.
  Data should be pre-encoded in one of the printer's supported languages.
  """
  @spec add_job(term(), binary()) :: {:ok, number()} | {:error, term()}
  def add_job(printer_id, job_data) do
    case Registry.get(printer_id) do
      pid when is_pid(pid) ->
        GenServer.call(pid, {:add_job, job_data})

      other ->
        other
    end
  end

  @doc "Cancels a single job currently in the printer's queue."
  @spec cancel_job(term(), binary()) :: :ok | {:error, term()}
  def cancel_job(printer_id, job_id), do: GenServer.call(printer_id, {:cancel_job, job_id})

  @doc "Cancels all jobs currently in the printer's queue."
  @spec cancel_all_jobs(term()) :: :ok
  def cancel_all_jobs(printer_id), do: GenServer.call(printer_id, :cancel_all_jobs)

  # --- GenServer Callbacks ---

  @impl true
  def init(opts) do
    printer_id = Map.fetch!(opts, :printer_id)
    adapter_module = Map.fetch!(opts, :adapter_module)
    adapter_config = Map.fetch!(opts, :adapter_config)

    adapter_state_instance = struct!(adapter_module, adapter_config)

    state = %__MODULE__{
      printer_id: printer_id,
      adapter_module: adapter_module,
      adapter_config: adapter_config,
      adapter_state: adapter_state_instance,
      job_queue: :queue.new(),
      prev_job_id: 0,
      connect_retry_timer: nil,
      connect_retries: 0,
      connection_monitor_ref: nil,
      stop: false
    }

    Logger.info("Printer #{printer_id} initialized with adapter: #{inspect(adapter_module)}.")
    Process.send_after(self(), :connect_retry, 0)

    {:ok, state}
  end

  @impl true
  def handle_call(:connect, _from, %{connected?: true} = state) do
    {:reply, {:ok, :already_connected}, state}
  end

  @impl true
  def handle_call(:connect, _form, state) do
    new_state = attempt_connection(state)
    reply = if new_state.connected?, do: :ok, else: {:error, :connection_failed}
    {:reply, reply, new_state}
  end

  @impl true
  def handle_call(:disconnect, _from, state) do
    new_state = do_disconnect(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status_info = %{
      printer_id: state.printer_id,
      connected?: state.connected?,
      jobs: :queue.to_list(state.job_queue),
      # Delegate to the adapter to get the status
      adapter_status: state.adapter_module.status(state.adapter_state)
    }

    {:reply, {:ok, status_info}, state}
  end

  @impl true
  def handle_call({:add_job, data}, _from, state) do
    job = struct!(PrintJob, id: state.prev_job_id + 1, data: data)
    new_queue = :queue.in(job, state.job_queue)
    new_state = %{state | job_queue: new_queue, prev_job_id: job.id}

    Process.send_after(self(), :process_queue, 0)

    Logger.debug(
      (
        "Printer #{state.printer_id}:"
        " Job #{job.id} added to queue."
        " Queue size: #{:queue.len(new_queue)}"
      )
    )

    broadcast_job(state.printer_id, job.id, "created")

    {:reply, {:ok, job.id}, new_state}
  end

  @impl true
  def handle_info(:process_queue, state) do
    Logger.debug("Printer #{state.printer_id}: processing queue.. #{inspect(state)}")
    new_state = process_next_job(state)

    if :queue.len(new_state.job_queue) == 0 and state.stop,
      do: {:stop, :shutdown, new_state},
      else: {:noreply, state}
  end

  # We monitor the adapter's GenServer. Here we handle if it goes down.
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{connection_monitor_ref: ref} = state) do
    Logger.error(
      "Printer #{state.printer_id}: Monitored resource (adapter connection) went down. Reason: #{inspect(reason)}. Attempting to reconnect."
    )

    # Clean up old monitor, mark as disconnected, and try to reconnect
    Process.demonitor(ref, [:flush])

    new_state = %{
      state
      | connected?: false,
        adapter_state: struct!(state.adapter_module, state.adapter_config),
        connection_monitor_ref: nil,
        current_connect_retries: 0
    }

    {:noreply, schedule_connect_retry(new_state)}
  end

  # Other types of adapters may need to be handled separately.
  def handle_info({:DOWN, _ref, _, _, _} = msg, state) do
    Logger.warning(
      "Printer #{state.printer_id}: unhandled DOWN message received: #{inspect(msg)}"
    )

    {:noreply, state}
  end

  def handle_info(:stop, state) do
    Logger.debug("Printer #{state.printer_id}: requested to stop")
    {:noreply, %{state | stop: true}}
  end

  def handle_info(:connect_retry, state) do
    Logger.warning("Printer #{state.printer_id}: retrying connection")

    {:noreply, attempt_connection(state)}
  end

  # --- Internal API ---

  defp broadcast_job(printer_id, job_id, message),
    do:
      Phoenix.PubSub.broadcast_from(
        @pubsub,
        self(),
        "#{printer_id}:#{job_id}",
        message
      )

  defp attempt_connection(state) do
    case state.adapter_module.connect(state.adapter_state) do
      {:ok, new_adapter_state} ->
        Logger.info("Printer #{state.printer_id}: Connection successful.")
        # Monitor critical resources if applicable (e.g., UART pid)
        new_monitor_ref = monitor_adapter_resource(new_adapter_state)

        new_state =
          %{
            state
            | connected?: true,
              adapter_state: new_adapter_state,
              connect_retries: 0,
              connect_retry_timer: nil,
              connection_monitor_ref: new_monitor_ref
          }

        # Process queue if items exist
        process_next_job(new_state)

      {:error, reason} ->
        Logger.error("Printer #{state.printer_id}: Connection failed. Reason: #{inspect(reason)}")

        schedule_connect_retry(%{state | connected?: false})
    end
  end

  defp schedule_connect_retry(state) do
    if state.current_connect_retries < state.max_connect_retries do
      Logger.info(
        "Printer #{state.printer_id}: Scheduling connection retry (#{state.current_connect_retries + 1}/#{state.max_connect_retries}) in #{state.connect_retry_delay_ms}ms."
      )

      timer_ref = Process.send_after(self(), :connect_retry, state.connect_retry_delay_ms)

      %{
        state
        | connect_retry_timer: timer_ref,
          current_connect_retries: state.current_connect_retries + 1
      }
    else
      Logger.error(
        "Printer #{state.printer_id}: Max connection retries reached. Will not retry automatically for now."
      )

      GenServer.stop(state.printer_id, :connection_failed)

      state
    end
  end

  defp process_next_job(%{connected?: false} = state) do
    # Cannot process if not connected
    state
  end

  defp process_next_job(state) do
    case :queue.out(state.job_queue) do
      {{:value, %PrintJob{id: id, data: data_to_print}}, new_queue} ->
        Logger.debug("Printer #{state.printer_id}: Sending job #{inspect(id)}.")

        updated_state = %{state | job_queue: new_queue}

        case state.adapter_module.print(state.adapter_state, data_to_print) do
          :ok ->
            Logger.info(
              "Printer #{state.printer_id}: Job sent successfully #{inspect(id)}. Jobs remaining: #{:queue.len(new_queue)}"
            )

            # Schedule processing of the next job, if any
            if :queue.is_empty(new_queue) do
              updated_state
            else
              # Process next job in a new message to allow other messages to interleave
              Process.send_after(self(), :process_queue, 0)
              updated_state
            end

          {:error, reason} ->
            Logger.error(
              "Printer #{state.printer_id}: Print failed. Reason: #{inspect(reason)}. Re-queuing job and attempting to reconnect."
            )

            # Put job back at the front of the queue
            re_queued_job_queue = :queue.in_r(data_to_print, new_queue)
            # Connection is likely compromised. Disconnect and attempt to reconnect.
            # state.adapter_module.print might have already updated adapter_state on error (e.g., closed socket)
            # We need to ensure adapter_state reflects the failure
            disconnected_adapter_state =
              case state.adapter_module.disconnect(state.adapter_state) do
                {:ok, disconnected_state} -> disconnected_state
                # Fallback to initial config
                _ -> struct!(state.adapter_module, state.adapter_config)
              end

            new_state_after_print_fail = %{
              updated_state
              | job_queue: re_queued_job_queue,
                # Assume connection is lost
                connected?: false,
                adapter_state: disconnected_adapter_state,
                # Reset retries for immediate reconnect attempt
                current_connect_retries: 0
            }

            schedule_connect_retry(new_state_after_print_fail)
        end

      {:empty, _new_queue} ->
        # Queue is empty, nothing to do
        state
    end
  end

  defp do_disconnect(state) do
    # Cancel any pending retry timer
    if state.connect_retry_timer, do: Process.cancel_timer(state.connect_retry_timer)
    # Demonitor resource
    if state.connection_monitor_ref, do: Process.demonitor(state.connection_monitor_ref, [:flush])

    {:ok, disconnected_adapter_state} = state.adapter_module.disconnect(state.adapter_state)
    Logger.info("Printer #{state.printer_id}: Disconnected by request.")

    %{
      state
      | connected?: false,
        adapter_state: disconnected_adapter_state,
        connect_retry_timer: nil,
        connection_monitor_ref: nil,
        # Reset retries
        current_connect_retries: 0
    }
  end

  # Monitor critical resources of the adapter, like the UART GenServer process
  defp monitor_adapter_resource(%Adapter.SerialPrinter{uart_ref: uart_pid} = _adapter_state)
       when is_pid(uart_pid) do
    Process.monitor(uart_pid)
  end

  defp monitor_adapter_resource(_adapter_state) do
    nil
  end
end
