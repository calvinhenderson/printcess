defmodule PrintClient.Printer.Queue do
  use GenServer

  alias PrintClient.Printer
  alias Phoenix.PubSub

  require Logger

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
  def subscribe(), do: Phoenix.PubSub.subscribe(PrintClient.PubSub, @topic)

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

  @impl true
  def handle_cast({:delete, job_id}, state) do
    state = delete_job_from_queue(job_id, state)
    {:noreply, state}
  end

  @doc """
  Adds a job to the queue.
  """
  @impl true
  def handle_cast({:push, data}, state) do
    with {:ok, data} <- Printer.Labels.validate_label_map(data) do
      job_id = state.last_job_id + 1

      data =
        data
        |> Map.put(:id, job_id)
        |> Map.put(:entered_queue_at, DateTime.utc_now())

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

      {:noreply, state}
    else
      error ->
        Logger.debug(
          "Invalid job data received: #{inspect(data)}, reason: #{inspect(error)}"
        )

        {:noreply, state}
    end
  end

  @doc """
  Executes a job for each unique printer in the queue (if the printer is available).
  """
  @impl true
  def handle_info(:work, %{jobs: jobs} = state)
      when is_list(jobs) and length(jobs) > 0 do
    Enum.uniq_by(jobs, & &1.printer)
    |> Task.async_stream(fn job ->
      if Printer.ready?(job.printer) do
        Printer.print(job)
        {:delete, job}
      else
        {:retry, job}
      end
    end)
    |> Enum.to_list()
    |> Enum.map_reduce(state.jobs, fn res, acc ->
      case res do
        {:ok, {:delete, job}} ->
          {job, delete_job_from_queue(job.id, acc)}

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

  defp delete_job_from_queue(job_id, %{jobs: jobs} = state) do
    jobs = delete_job_from_queue(job_id, jobs)
    Map.put(state, :jobs, jobs)
  end

  defp delete_job_from_queue(job_id, jobs) when is_list(jobs) do
    broadcast_job(:delete, job_id)
    Enum.reject(jobs, &(&1.id == job_id))
  end

  defp broadcast_job(action, job),
    do: PubSub.broadcast(PrintClient.PubSub, "job-queue", {action, job})

  defp schedule_work do
    Process.send_after(self(), :work, :timer.seconds(1))
  end
end
