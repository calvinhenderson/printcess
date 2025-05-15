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

  def start_printer(config) do
    spec = {Printer.Device, Printer.Adapter.load_config(config)}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_printer(printer_id) do
    Printer.Registry.get(printer_id)
    |> case do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      error ->
        error
    end
  end
end
