defmodule PrintClient.Printer.Supervisor do
  use DynamicSupervisor

  alias PrintClient.Printer
  alias PrintClient.Settings

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
      {:ok, pid} -> {:ok, pid, printer}
      {:error, {:already_started, pid}} -> {:ok, pid, printer}
      error -> raise inspect(error)
    end
  end

  def stop_printer(printer_id) do
    Printer.Registry.get(printer_id)
    |> case do
      pid when is_pid(pid) ->
        send(pid, :stop)
        :timer.send_after(30_000, self(), {:kill, pid})

      error ->
        error
    end
  end

  def handle_info({:kill, pid}, state) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
    {:noreply, state}
  end
end
