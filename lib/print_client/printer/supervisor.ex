defmodule PrintClient.Printer.Supervisor do
  use DynamicSupervisor

  alias PrintClient.Printer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_printer(printer) do
    spec = {Printer, printer}

    DynamicSupervisor.start_child(__MODULE__, spec)
    |> case do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> raise inspect(error)
    end
  end

  def stop_printer(printer_id) do
    Printer.Registry.get(printer_id)
    |> case do
      pid when is_pid(pid) ->
        send(pid, :stop)
        :timer.send_after(self(), {:kill, pid}, 30_000)

      error ->
        error
    end
  end

  @impl true
  def handle_info({:kill, pid}, state) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
    {:noreply, state}
  end
end
