defmodule PrintClient.AssetsApi do
  @doc """
  Searches an API for users 
  """
  def search_users(query, opts \\ []) do
    backend = adapter()
    backend.module.search_users(backend.config, query, opts)
  end

  @doc """
  Searches an API for assets
  """
  def search_assets(query, opts \\ []) do
    backend = adapter()
    backend.module.search_assets(backend.config, query, opts)
  end

  defp adapter do
    adapter = config(:adapter)
    settings = PrintClient.Settings.get_config()

    %{
      module: adapter,
      config: adapter.config(settings)
    }
  end

  defp config(key) when is_atom(key) do
    Application.get_env(:print_client, __MODULE__, [])
    |> Keyword.fetch!(key)
  end
end
