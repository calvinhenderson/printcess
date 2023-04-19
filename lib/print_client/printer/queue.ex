defmodule PrintClient.Printer.Queue do
  use GenServer

  alias PrintClient.Printer

  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    schedule_work()

    {:ok, []}
  end

  @impl true
  def handle_cast({:push, data}, state) do
    with {:ok, data} <- Printer.Labels.validate_label_map(data) do
      Logger.debug("Pushed job to queue: #{inspect data}")
      {:noreply, [data | state]}
    else
      error ->
        Logger.debug("Invalid job data received: #{inspect data}, reason: #{inspect error}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:work, state) when is_list(state) and length(state) > 0 do
    schedule_work()
    {job, remaining_jobs} = List.pop_at(state, -1)
    if Printer.ready?(job.printer) do
      Printer.print(job)
      {:noreply, remaining_jobs}
    else
      {:noreply, state}
    end
  end
  def handle_info(:work, state) do
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.seconds(1))
  end
end
