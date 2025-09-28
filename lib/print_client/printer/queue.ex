defmodule PrintClient.Printer.Queue do
  use GenServer

  alias PrintClient.Printer

  require Logger

  @pubsub PrintClient.PubSub
  @topic "job-queue"

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    schedule_work()

    {:ok, %{last_job_id: 0, jobs: []}}
  end

  @doc """
  Subscribes to the queue messages.
  """
  def subscribe(), do: PrintClient.PubSub.subscribe(@pubsub, @topic)

  @doc """
  Adds a job to the job queue.
  """
  @spec submit_job(Map.t(), number() | nil) :: {:ok, number()} | {:error, term()}
  def submit_job(params, timeout \\ 5000) do
    GenServer.call(PrintQueue, {:push, params}, timeout)
  end

  @doc """
  Deletes a job from the queue.
  """
  @spec delete_job(number()) :: :ok
  def delete_job(job_id) do
    GenServer.cast(PrintQueue, {:delete, job_id})
  end

  @doc """
  Returns the list of active jobs in the queue.
  """
  def list_jobs do
    GenServer.call(PrintQueue, :jobs, 30_000)
  end

  @impl true
  def handle_call(:jobs, _from, state) do
    {:reply, state.jobs, state}
  end

  @doc """
  Adds a job to the queue.
  """
  @impl true
  def handle_call({:push, data}, _from, state) do
    with {:ok, data} <- Printer.Labels.validate_label_map(data) do
      job_id = state.last_job_id + 1

      data =
        data
        |> Map.put(:id, job_id)
        |> Map.put(:entered_queue_at, DateTime.utc_now())
        |> Map.put(:status, :pending)

      broadcast_job(:push, data)

      jobs =
        state.jobs
        |> Enum.reverse()
        |> then(&[data | &1])
        |> Enum.reverse()

      state =
        state
        |> Map.put(:last_job_id, job_id)
        |> Map.put(:jobs, jobs)

      {:reply, {:ok, job_id}, state}
    else
      error ->
        Logger.debug("Invalid job data received: #{inspect(data)}, reason: #{inspect(error)}")

        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_cast({:delete, job_id}, state) do
    state = delete_job_from_queue(job_id, state)
    {:noreply, state}
  end

  @doc """
  Executes a job for each unique printer in the queue (if the printer is available).
  """
  @impl true
  def handle_info(:work, %{jobs: jobs} = state)
      when is_list(jobs) and length(jobs) > 0 do
    jobs
    |> Enum.filter(&(&1.status in [:pending]))
    |> Enum.uniq_by(& &1.printer)
    |> Task.async_stream(fn job ->
      if Printer.ready?(job.printer) do
        Printer.print(job)
        {:complete, job}
      else
        {:retry, job}
      end
    end)
    |> Enum.to_list()
    |> Enum.map_reduce(state.jobs, fn res, acc ->
      case res do
        {:ok, {:complete, job}} ->
          {job, complete_job_in_queue(job.id, acc)}

        _ ->
          {nil, acc}
      end
    end)
    |> then(fn {_, acc} ->
      state =
        state
        |> Map.put(:jobs, acc)

      schedule_work()

      {:noreply, state}
    end)
  end

  def handle_info(:work, state) do
    schedule_work()
    {:noreply, state}
  end

  defp complete_job_in_queue(job_id, %{jobs: jobs} = state) do
    jobs = complete_job_in_queue(job_id, jobs)
    Map.put(state, :jobs, jobs)
  end

  defp complete_job_in_queue(job_id, jobs) when is_list(jobs) do
    broadcast_job(:complete, job_id)

    Enum.map(jobs, fn job ->
      if job.id == job_id do
        Map.put(job, :status, :complete)
      else
        job
      end
    end)
  end

  defp delete_job_from_queue(job_id, %{jobs: jobs} = state) do
    jobs = delete_job_from_queue(job_id, jobs)
    Map.put(state, :jobs, jobs)
  end

  defp delete_job_from_queue(job_id, jobs) when is_list(jobs) do
    broadcast_job(:deleted, job_id)

    Enum.map(jobs, fn j ->
      case j do
        %{id: job_id} -> %{j | status: :deleted}
        j -> j
      end
    end)
  end

  defp broadcast_job(action, job),
    do: PrintClient.PubSub.broadcast(@pubsub, "job-queue", {action, job})

  defp schedule_work do
    Process.send_after(self(), :work, :timer.seconds(1))
  end
end
