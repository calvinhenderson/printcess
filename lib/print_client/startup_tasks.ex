defmodule PrintClient.StartupTasks do
  use GenServer

  def start_link(opts) do
    window_size = Keyword.fetch!(opts, :window_size)
    GenServer.start_link(__MODULE__, %{window_size: window_size})
  end

  @impl true
  def init(%{window_size: window_size}) do
    PrintClient.Repo.initialize()

    :wx.set_env(Desktop.Env.wx_env())
    frame = Desktop.Window.frame(PrintClientWindow)

    :wxWindow.setMinSize(frame, window_size)
    :wxWindow.setMaxSize(frame, window_size)
    :wxWindow.setSize(frame, window_size)

    :ignore
  end
end
