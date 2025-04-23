defmodule PrintClient.Printer.Adapter do
  @moduledoc """
  Defines the basic behaviour for all print interfaces.

  ## Usage:

      defmodule MyCustomAdapter do
        use PrintClient.Adapter
      
        @impl true
        def send(config, data), do: ...

        @impl true
        def ready(config), do: ...
      end
  """

  @doc """
  Sends the TSPL2 command data to the printer. Handles the low-level communication of the printer.
  """
  @callback send(adapter_config :: __MODULE__.Config.t(), data :: binary()) ::
              :ok | {:error, term()}

  @doc """
  Asks the printer if it is ready to receive data. If ready, it returns a stateful connection.
  """
  @callback ready(adapter_config :: __MODULE__.Config.t()) ::
              {:ok, state :: term()} | :not_ready | {:error, term()}

  defmodule PrintClient.Printer.Adapter.Config do
    @moduledoc """
    Defines the config structure for print adapters.
    """
    @type t :: %__MODULE__{ip_address: binary, port: integer, path: binary, name: binary}
    defstruct [:ip_address, :port, :path, :name]
  end

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
end
