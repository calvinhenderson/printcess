defmodule PrintClient.Printer do
  @moduledoc """
  Interfaces with label printers through the use of protocols and adapters.
  """

  use GenServer, restart: :transient

  require Logger

  alias Hex.Solver.Registry
  alias PrintClient.Printer.{Adapter, PrintJob, Registry, Discovery}
  alias PrintClient.Label
  alias PrintClient.Settings

  defstruct printer_id: nil,
            encoding: nil,
            name: nil,
            type: nil,
            adapter_module: nil,
            adapter_config: nil,
            adapter_state: nil,
            job_queue: nil,
            processed_jobs: [],
            prev_job_id: 0,
            connected?: false,
            connect_retry_timer: nil,
            connect_retry_delay_ms: 1000,
            connect_retries: 0,
            connect_max_retries: 5,
            connection_monitor_ref: nil,
            stop: false

  @type t :: [
          printer_id: String.t(),
          encoding: String.t() | nil,
          name: :string | nil,
          type: atom() | nil,
          adapter_module: Module.t() | nil,
          adapter_config: Map.t() | nil,
          adapter_state: term(),
          job_queue: :queue.new(),
          processed_jobs: List.t(),
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
  @heartbeat_interval 15_000

  # --- Client API ---

  @spec start_link(map()) :: GenServer.start_link()
  def start_link(opts) do
    printer_id = Map.fetch!(opts, :printer_id)
    GenServer.start_link(__MODULE__, opts, name: Registry.via_tuple(printer_id))
  end

  @doc """
  Returns the topic string for a given printer.
  """
  @spec topic(__MODULE__.t() | Settings.Printer.t() | binary()) :: binary()
  def topic(%{printer_id: printer_id}), do: topic(printer_id)
  def topic(%Settings.Printer{} = printer), do: Discovery.id_of_printer(printer) |> topic()
  def topic(printer_id), do: "printers:#{printer_id}"

  @doc """
  Returns the topic string for a given printer's job.
  """
  @spec topic(__MODULE__.t() | Settings.Printer.t() | binary(), number()) :: binary()
  def topic(printer_id, job_id), do: topic(printer_id) <> ":#{job_id}"

  @doc """
  Subscribes the calling process to the printer's topic.
  """
  def subscribe(printer),
    do: PrintClient.PubSub.subscribe(@pubsub, topic(printer))

  @doc """
  Subscribes to a specific printer's job.
  """
  def subscribe(printer, job_id),
    do: PrintClient.PubSub.subscribe(@pubsub, topic(printer, job_id))

  @doc """
  Unsubscribes the calling process from the printer's topic.
  """
  def unsubscribe(printer),
    do: PrintClient.PubSub.unsubscribe(@pubsub, topic(printer))

  @doc """
  Unsubscribes the calling process from the printer's job topic.
  """
  def unsubscribe(printer, job_id),
    do: PrintClient.PubSub.unsubscribe(@pubsub, topic(printer, job_id))

  @doc "Opens a connection to the physical printer."
  def connect(printer_id), do: GenServer.call(Registry.via_tuple(printer_id), :connect)

  @doc "Closes a connection to the physical printer."
  def disconnect(printer_id), do: GenServer.call(Registry.via_tuple(printer_id), :disconnect)

  @doc "Gets a printer's status."
  @spec status(term()) :: Map.t()
  def status(printer_id), do: GenServer.call(Registry.via_tuple(printer_id), :status)

  @doc """
  Adds a new job to the printer's queue.

  The job will be dispatched as soon as the printer becomes available.
  Data should be pre-encoded in one of the printer's supported languages.
  """
  @spec add_job(Settings.Printer.t() | __MODULE__.t() | term(), Label.Template.t(), Map.t()) ::
          {:ok, term()} | {:error, term()}
  def add_job(%Settings.Printer{} = printer, template, params),
    do: add_job(Discovery.id_of_printer(printer), template, params)

  def add_job(%__MODULE__{printer_id: printer_id}, template, params),
    do: add_job(printer_id, template, params)

  def add_job(printer_id, template, params),
    do: GenServer.call(Registry.get(printer_id), {:add_job, template, params})

  @doc "Gets a single job's information from the queue."
  @spec get_job(Settings.Printer.t() | __MODULE__.t() | term(), term()) :: {:ok, PrintJob.t()} | {:error, :not_found}
  def get_job(%Settings.Printer{} = printer, job_id),
    do: get_job(Discovery.id_of_printer(printer), job_id)
  def get_job(%__MODULE__{printer_id: printer_id}, job_id),
    do: get_job(printer_id, job_id)
  def get_job(printer_id, job_id), do: GenServer.call(Registry.via_tuple(printer_id), {:get_job, job_id})


  @doc "Cancels a single job currently in the printer's queue."
  @spec cancel_job(Settings.Printer.t() | __MODULE__.t() | term(), term()) :: :ok | {:error, term()}
  def cancel_job(%Settings.Printer{} = printer, job_id),
    do: cancel_job(Discovery.id_of_printer(printer), job_id)

  def cancel_job(%__MODULE__{printer_id: printer_id}, job_id),
    do: cancel_job(printer_id, job_id)

  def cancel_job(printer_id, job_id),
    do: GenServer.call(Registry.via_tuple(printer_id), {:cancel_job, job_id})

  @doc "Cancels all jobs currently in the printer's queue."
  @spec cancel_all_jobs(term()) :: :ok
  def cancel_all_jobs(printer_id), do: GenServer.call(Registry.via_tuple(printer_id), :cancel_all_jobs)

  # --- GenServer Callbacks ---

  @impl true
  def init(opts) do
    printer_id = Map.fetch!(opts, :printer_id)
    encoding = Map.fetch!(opts, :encoding)
    name = Map.get(opts, :name, printer_id)
    adapter_module = Map.fetch!(opts, :adapter_module)
    adapter_config = Map.fetch!(opts, :adapter_config)
    adapter_state_instance = struct!(adapter_module, adapter_config)

    state = %__MODULE__{
      name: name,
      printer_id: printer_id,
      encoding: encoding,
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
    # Process.send_after(self(), :connect_retry, 0)
    Process.send_after(self(), :heartbeat, 0)

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
      name: state.name,
      connected?: state.connected?,
      jobs: :queue.to_list(state.job_queue),
      # Delegate to the adapter to get the status
      adapter_status: state.adapter_module.status(state.adapter_state)
    }

    {:reply, {:ok, status_info}, state}
  end

  @impl true
  def handle_call({:get_job, job_id}, _from, state) do
    state.job_queue
    |> :queue.to_list()
    |> then(&(&1 ++ state.processed_jobs))
    |> Enum.find(&(&1.id == job_id))
    |> case do
      %PrintJob{} = job -> {:ok, job}
      nil -> {:error, :not_found}
    end
    |> then(&{:reply, &1, state})
  end

  @impl true
  def handle_call({:add_job, template, params}, _from, state) do
    job =
      struct!(
        PrintJob,
        id: state.prev_job_id + 1,
        template: template,
        params: params
      )

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

    broadcast(state.printer_id, job, :job_added)

    {:reply, {:ok, job.id}, new_state}
  end

  @impl true
  def handle_call({:cancel_job, job_id}, _from, state) do
    job =
      state.job_queue
      |> :queue.to_list()
      |> Enum.find(&(&1.id == job_id))

    new_state =
      case job do
        %PrintJob{} = job ->
          %{state
            | job_queue: :queue.delete(job, state.job_queue),
              processed_jobs: [%{job | status: :cancelled} | state.processed_jobs]}
        nil ->
          state
      end

    broadcast_job(state.printer_id, job_id, :cancelled)

    Logger.info("Printer #{state.printer_id}: cancelled job #{job_id}")

    {:reply, {:ok, job_id}, new_state}
  end

  @impl true
  def handle_info(:process_queue, state) do
    Logger.debug("Printer #{state.printer_id}: processing queue.. #{inspect(state)}")
    new_state = process_next_job(state)

    cond do
      :queue.len(new_state.job_queue) == 0 and state.stop -> {:stop, :shutdown, new_state}
      :queue.len(new_state.job_queue) == 0 -> {:noreply, do_disconnect(new_state)}
      true -> {:noreply, new_state}
    end
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
        connect_retries: 0
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
    new_state = %{state | stop: true}

    if :queue.len(state.job_queue) == 0 do
      {:stop, :shutdown, new_state}
    else
      # Just set the stop flag so we can close when the print queue is finished.
      {:noreply, state}
    end
  end

  def handle_info(:connect_retry, state) do
    Logger.warning("Printer #{state.printer_id}: retrying connection")

    {:noreply, attempt_connection(state)}
  end

  def handle_info(:heartbeat, state) do
    online? =
      struct!(state.adapter_module, state.adapter_config)
      |> state.adapter_module.online?()

    broadcast(state.printer_id, online?, :status)
    Process.send_after(self(), :heartbeat, @heartbeat_interval)

    {:noreply, state}
  end

  # --- Internal API ---

  defp broadcast(printer_id, message, type \\ :info),
    do:
      PrintClient.PubSub.broadcast_from(
        @pubsub,
        self(),
        topic(printer_id),
        {printer_id, type, message}
      )

  defp broadcast_job(printer_id, job_id, status \\ :sent),
    do:
      PrintClient.PubSub.broadcast_from(
        @pubsub,
        self(),
        topic(printer_id, job_id),
        {printer_id, {:job, job_id}, status}
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

      {:error, reason, failed_connection_adapter_state} ->
        Logger.error("Printer #{state.printer_id}: Connection failed. Reason: #{inspect(reason)}")

        schedule_connect_retry(%{
          state
          | connected?: false,
            adapter_state: failed_connection_adapter_state
        })
    end
  end

  defp schedule_connect_retry(state) do
    broadcast(state.printer_id, "Printer #{state.name} disconnected. Reconnecting..", :error)

    delay =
      if (state.connect_retries / state.connect_max_retries) == 0,
        do: state.connect_retry_delay_ms,
        else: state.connect_retry_delay_ms * 10

    Logger.info(
      "Printer #{state.printer_id}: Scheduling connection retry (#{state.connect_retries + 1}) in #{delay}ms."
    )

    timer_ref = Process.send_after(self(), :connect_retry, delay)

    %{
      state
      | connect_retry_timer: timer_ref,
        connect_retries: state.connect_retries + 1
    }
  end

  defp process_next_job(%{connected?: false} = state) do
    # Cannot process if not connected
    attempt_connection(state)
  end

  defp process_next_job(state) do
    with {{:value, %PrintJob{id: job_id} = job}, new_queue} <- :queue.out(state.job_queue),
      _ <- broadcast_job(state.printer_id, job_id, :processing),
         {:ok, data} <- get_job_data(state, job) do
      Logger.debug("Printer #{state.printer_id}: Sending job #{inspect(job_id)}.")

      state.adapter_state
      |> state.adapter_module.print(data)
      |> handle_print_result(state, job, new_queue)
    else
      {:error, reason} ->
        Logger.error("Printer #{state.printer_id}: Failed to get job from queue.")
        Logger.debug(inspect({:error, reason}))
    end
  end

  defp handle_print_result(:ok, state, %PrintJob{} = job, remaining_queue) do
    Logger.info(
      "Printer #{state.printer_id}: Job sent successfully #{inspect(job.id)}. Jobs remaining: #{:queue.len(remaining_queue)}"
    )

    updated_state = %{
      state
      | job_queue: remaining_queue,
        processed_jobs: [%{job | status: :complete} | state.processed_jobs] |> Enum.take(50)
    }

    broadcast_job(state.printer_id, job.id, :complete)

    # Schedule processing of the next job, if any
    if :queue.is_empty(remaining_queue) do
      updated_state
    else
      # Process next job in a new message to allow other messages to interleave
      Process.send_after(self(), :process_queue, 0)
      updated_state
    end
  end

  defp handle_print_result({:error, reason, errored_adapter_state}, state, %PrintJob{} = job, remaining_queue) do
    Logger.error(
      "Printer #{state.printer_id}: Print failed. Reason: #{inspect(reason)}. Re-queuing job and attempting to reconnect."
    )

    broadcast(
      state.printer_id,
      "Print job #{job.id} failed for #{state.name}. Will try again.",
      :error
    )

    broadcast_job(state.printer_id, job.id, :failed)

    # Connection is likely compromised. Disconnect and attempt to reconnect.
    # state.adapter_module.print might have already updated adapter_state on error (e.g., closed socket)
    # We need to ensure adapter_state reflects the failure
    disconnected_adapter_state =
      case state.adapter_module.disconnect(errored_adapter_state) do
        {:ok, disconnected_state} -> disconnected_state
        # Fallback to initial config
        _ -> struct!(state.adapter_module, state.adapter_config)
      end

    new_state_after_print_fail = %{
      state
      | # Insert the failed job back into the queue
        job_queue: :queue.in_r(%{job | status: :failed}, remaining_queue),
        # Assume connection is lost
        connected?: false,
        adapter_state: disconnected_adapter_state,
        # Reset retries for immediate reconnect attempt
        connect_retries: 0
    }

    schedule_connect_retry(new_state_after_print_fail)
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
        connect_retries: 0
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

  defp get_job_data(_state, %PrintJob{data: <<data>>}), do: {:ok, data}

  defp get_job_data(
         state,
         %PrintJob{template: %Label.Template{} = template, params: params} = job
       ) do
    with %{} = validated when map_size(validated) > 0 <- params,
         rendered <- Label.render(template, validated),
         {:ok, data} <-
           Label.encode(state.encoding, rendered, copies: Map.get(validated, :copies, 1)) do
      {:ok, data}
    else
      {:error, reason} ->
        Logger.error("Job #{job.id}: Failed to render template.")
        {:error, reason}
    end
  end
end
