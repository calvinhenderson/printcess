def PrintClient.Printer do
  @moduledoc """
  Interfaces with label printers through the use of protocols and adapters.
  """

  alias PrintClient.Printer.{Supervisor, Adapter}

  use GenServer

  def init() do
    Supervisor.start_link(Supervisor, nil)
  end
end
