defmodule PrintClient.StartupTasks do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    PrintClient.Repo.initialize()
    :ignore
  end
end
