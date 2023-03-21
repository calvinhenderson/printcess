defmodule PrintClient.Repo do
  use Ecto.Repo,
    otp_app: :print_client,
    adapter: Ecto.Adapters.SQLite3

  require Logger

  def initialize() do
    Ecto.Adapters.SQL.query!(__MODULE__, """
      CREATE TABLE IF NOT EXISTS printers (
        id INTEGER PRIMARY KEY ASC,
        name VARCHAR,
        hostname VARCHAR NOT NULL,
        port INTEGER NOT NULL DEFAULT 9100,
        selected INTEGER NOT NULL DEFAULT 0
      );

      CREATE UNIQUE INDEX IF NOT EXISTS printers_hostname_index ON printers( hostname );
    """)
    Logger.info("Initialize settings repository")
  end
end
