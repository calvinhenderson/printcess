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
        hostname VARCHAR,
        port INTEGER NOT NULL DEFAULT 9100,
        serial_port VARCHAR,
        vendor_id VARCHAR,
        product_id VARCHAR,
        encoding VARCHAR NOT NULL,
        autoconnect BOOLEAN DEFAULT false,
        type VARCHAR NOT NULL
      );

      CREATE UNIQUE INDEX IF NOT EXISTS printers_v2_network_printer_index ON printers_v2( hostname, protocol ) WHERE hostname IS NOT NULL AND protocol IS NOT NULL;
      CREATE UNIQUE INDEX IF NOT EXISTS printers_v2_serial_printer_index ON printers_v2( serial_port, protocol ) WHERE serial_port IS NOT NULL AND protocol IS NOT NULL;
      CREATE UNIQUE INDEX IF NOT EXISTS printers_v2_usb_printer_index ON printers_v2( vendor_id, product_id, protocol ) WHERE vendor_id IS NOT NULL AND product_id IS NOT NULL AND protocol IS NOT NULL;
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
