defmodule PrintClient.Printer.Adapter do
  @moduledoc """
  Specifies the behaviour for printing adapters.
  """

  @type t :: module()

  @spec close(GenServer.server()) :: :ok | {:error, term()}
  @callback close(GenServer.server())

  @spec write(GenServer.server()) :: :ok | {:error, term()}
  @callback write(GenServer.server(), term())

  @spec read(GenServer.server()) :: {:ok, binary()} | {:error, term()}
  @callback read(GenServer.server())

  @spec healthcheck(GenServer.server()) :: :ok | {:error, term()}
  @callback healthcheck(GenServer.server())
end
