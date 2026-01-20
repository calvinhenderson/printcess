defmodule PrintClient.Repo.SearchPathsTable do
  def query,
    do: """
      CREATE TABLE IF NOT EXISTS search_paths_v2 (
        id INTEGER PRIMARY KEY ASC,
        path VARCHAR NOT NULL,
        disabled BOOLEAN
      );

      CREATE UNIQUE INDEX IF NOT EXISTS search_paths_v2_path_index ON search_paths_v2( path );
    """
end
