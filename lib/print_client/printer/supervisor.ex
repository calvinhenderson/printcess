defmodule PrintClient.Printer.Supervisor do
  use DynamicSupervisor

  alias PrintClient.Printer
  alias PrintClient.Settings

  @pubsub PrintClient.PubSub
  @topic "printers:supervisor"

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_printer(%Settings.Printer{} = settings) do
    printer =
      settings
      |> Printer.Discovery.load_saved_printer()

    start_printer(printer)
  end

  def start_printer(%Printer{} = printer) do
    spec = {Printer, printer}

    DynamicSupervisor.start_child(__MODULE__, spec)
    |> case do
      {:ok, pid} ->
        broadcast({:started, printer.printer_id})
        {:ok, pid, printer}

      {:error, {:already_started, pid}} ->
        {:ok, pid, printer}

      error ->
        raise inspect(error)
    end
  end

  def stop_printer(printer_id) do
    Printer.Registry.get(printer_id)
    |> case do
      pid when is_pid(pid) ->
        broadcast({:stopping, printer_id})
        send(pid, :stop)
        :timer.send_after(30_000, self(), {:kill, pid})

      error ->
        error
    end
  end

  @doc """
  Subscribes to supervisor events.
  """
  @spec subscribe :: :ok
  def subscribe do
    PrintClient.PubSub.subscribe(@pubsub, @topic)
  end

  def handle_info({:kill, pid}, state) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
    {:noreply, state}
  end

  defp broadcast(msg) do
    PrintClient.PubSub.broadcast(@pubsub, @topic, msg)
  end
end
