defmodule PrintClient.AssetsApi do
  alias PrintClient.AssetsApi.SearchResult
  alias PrintClient.AssetsApi.ApiAdapter.{Iiq}

  @doc """
  Searches an API for users 
  """
  def backend do
    %Iiq{}
  end
end
