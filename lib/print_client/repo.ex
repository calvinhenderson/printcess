defmodule PrintClient.Repo do
  use Ecto.Repo,
    otp_app: :print_client,
    adapter: Ecto.Adapters.SQLite3

  require Logger

  def initialize() do
    Ecto.Adapters.SQL.query!(__MODULE__, """
      CREATE TABLE IF NOT EXISTS printers_v2 (
        id INTEGER PRIMARY KEY ASC,
        name VARCHAR NOT NULL,
        hostname VARCHAR NOT NULL,
        port INTEGER NOT NULL DEFAULT 9100,
        selected INTEGER NOT NULL DEFAULT 0
      );

      CREATE UNIQUE INDEX IF NOT EXISTS printers_v2_hostname_index ON printers_v2( hostname );
    """)

    Ecto.Adapters.SQL.query!(__MODULE__, """
      CREATE TABLE IF NOT EXISTS settings_v2 (
        id INTEGER PRIMARY KEY ASC,
        theme VARCHAR,
        instance VARCHAR NOT NULL,
        token VARCHAR NOT NULL,
        product_id VARCHAR NOT NULL
      );

      CREATE UNIQUE INDEX IF NOT EXISTS settings_v2_token_index ON settings_v2( token );
    """)

    Logger.info("Initialize settings repository")
  end
end
