defmodule PrintClient.Repo do
  use Ecto.Repo,
    otp_app: :print_client,
    adapter: Ecto.Adapters.SQLite3

  require Logger

  def initialize() do
    migrations = [
      __MODULE__.PrintersTable,
      __MODULE__.SettingsTable,
      __MODULE__.ViewsTable
    ]

    migrations
    |> Enum.map(fn mod ->
      Code.ensure_loaded(mod)

      cond do
        Kernel.function_exported?(mod, :queries, 0) ->
          queries = mod.queries()
          Enum.map(queries, &Ecto.Adapters.SQL.query!(__MODULE__, &1))
          Logger.info("Executing query for #{inspect(mod)}")

        Kernel.function_exported?(mod, :query, 0) ->
          query = mod.query()
          Ecto.Adapters.SQL.query!(__MODULE__, query)
          Logger.info("Executing query for #{inspect(mod)}")

        true ->
          Logger.debug(
            "[Repo] Ignoring module #{inspect(mod)} because it does not provide a query"
          )
      end
    end)

    Logger.info("Initialize settings repository")
  end
end
