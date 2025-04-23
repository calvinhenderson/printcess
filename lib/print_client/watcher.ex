defmodule PrintClient.Watcher do
  @moduledoc """
  Provides a GenServer for automatically discovering and connecting to printers.
  """

  use GenServer

  alias PrintClient.Printer.Adapter.SerialPrinter

  @hearbeat_interval 1000

  def start_link(printer) do
    hostname = Keyword.fetch!(printer, :hostname)
    GenServer.start_link(__MODULE__, printer, name: hostname)
  end

  @impl true
  def init(printer) do
    schedule_heartbeat()
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:heartbeat, state) do
    perform_discovery()
    schedule_heartbeat()
    {:noreply, state}
  end

  defp schedule_heartbeat, do: Process.send_after(self(), :heartbeat, @heartbeat_interval)

  defp perform_discovery
end
