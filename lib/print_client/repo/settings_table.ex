defmodule PrintClient.Repo.SettingsTable do
  def query,
    do: """
      CREATE TABLE IF NOT EXISTS settings_v2 (
        id INTEGER PRIMARY KEY ASC,
        theme VARCHAR,
        instance VARCHAR NOT NULL,
        token VARCHAR NOT NULL,
        product_id VARCHAR NOT NULL
      );

      CREATE UNIQUE INDEX IF NOT EXISTS settings_v2_token_index ON settings_v2( token );
    """
end
