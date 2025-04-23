defmodule PrintClient.Printer.Adapter do
  @moduledoc """
  Specifies the behaviour for printing adapters.
  """

  @type t :: module()

  @callback close(GenServer.server()) :: :ok | {:error, term()}
  @callback write(GenServer.server(), term()) :: :ok | {:error, term()}
  @callback read(GenServer.server()) :: {:ok, binary()} | {:error, term()}
  @callback healthcheck(GenServer.server()) :: :ok | {:error, term()}
end
