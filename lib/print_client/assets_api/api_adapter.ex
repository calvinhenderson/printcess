defprotocol PrintClient.AssetsApi.ApiAdapter do
  @moduledoc """
  Provides a protocol for implementing asset and user search API backends.
  """
  alias PrintClient.AssetsApi.SearchResult

  @doc "Establishes a connection to the printer."
  @spec search_assets(struct(), String.t(), Keyword.t()) ::
          {:ok, SearchResult.t()} | {:error, term()}
  def search_assets(config, query, opts \\ [])

  @doc "Establishes a connection to the printer."
  @spec search_users(struct(), String.t(), Keyword.t()) ::
          {:ok, SearchResult.t()} | {:error, term()}
  def search_users(config, query, opts \\ [])
end
