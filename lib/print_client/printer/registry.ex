defmodule PrintClient.Printer.Registry do
  alias PrintClient.Printer

  @doc """
  Returns a via tuple containing the registry information for the specified printer_id.
  """
  def via_tuple(printer_id) do
    {:via, Registry, {Printer.Registry, printer_id}}
  end

  @doc """
  Gets a single printer instance. Returns the pid of the controlling process if it exists, otherwise `{:error, :not_found}`.
  """
  @spec get(printer_id: term()) :: pid() | {:error, :not_found}
  def get(printer_id) do
    Registry.lookup(Printer.Registry, printer_id)
    |> case do
      [{printer_pid, _}] ->
        printer_pid

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Lists all printer instances known to the registry. Returns a list of printer_ids.
  """
  @spec list() :: [pid()] | []
  def list do
    Registry.select(Printer.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end
end
