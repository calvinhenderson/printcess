defmodule PrintClient.Discovery do
  @moduledoc """
  Provides a GenServer for automatically discovering and connecting to printers.
  """

  use GenServer

  alias Circuits.UART
  alias PrintClient.Printer.Adapter.SerialPrinter
  alias PrintClient.Printer

  @ownership_table :printer_ownership
  @hearbeat_interval 1000

  def start_link(printer) do
    hostname = Keyword.fetch!(printer, :hostname)
    GenServer.start_link(__MODULE__, printer, name: hostname)
  end

  @impl true
  def init(printer) do
    with false <- :mnesia.table()

    if not :mnesia.table_exists(@ownership_table) do
    end

    schedule_heartbeat()
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:heartbeat, state) do
    discover_printers()
    schedule_heartbeat()
    {:noreply, state}
  end

  defp schedule_heartbeat, do: Process.send_after(self(), :heartbeat, @heartbeat_interval)

  defp discover_printers do
    connected_printers = Supervisor.which_children(Printer.Supervisor)

    UART.enumerate()
    |> Enum.each(fn {port, info} ->
      if(connected_printers)
    end)
  end
end
