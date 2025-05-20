defmodule PrintClient.AssetsApi do
  alias PrintClient.Settings
  alias PrintClient.AssetsApi.ApiAdapter.{Iiq}

  def search_users(backend, query, opts \\ []),
    do: backend.module.search_users(backend.config, query, opts)

  def search_assets(backend, query, opts \\ []),
    do: backend.module.search_assets(backend.config, query, opts)

  @doc """
  Searches an API for users 
  """
  def backend do
    config = Settings.get_settings()

    %{
      module: Iiq,
      config: %Iiq{
        instance: config.instance,
        token: config.token,
        product_id: config.product_id
      }
    }
  end
end
