defmodule PrintClient.Repo.ViewsTable do
  def queries,
    do: [
      """
      CREATE TABLE IF NOT EXISTS views_v2 (
        id INTEGER PRIMARY KEY ASC,
        template INTEGER NOT NULL,
        temp BOOLEAN DEFAULT TRUE,
        inserted_at TIMESTAMP WITHOUT TIMEZONE DEFAULT 'NOW()'
      );
      """,
      """
      CREATE TABLE IF NOT EXISTS views_printers_v2 (
        printer_id INTEGER,
        view_id INTEGER,
        PRIMARY KEY ( printer_id, view_id )
        FOREIGN KEY ( view_id ) REFERENCES views_v2(id) ON DELETE CASCADE
        FOREIGN KEY ( printer_id ) REFERENCES printers_v2(id) ON DELETE CASCADE
      );
      """
    ]
end
