defmodule PrintClient.AssetsApi.SearchResult do
  defmodule User do
    alias PrintClient.AssetsApi.SearchResult.Asset

    defstruct id: "",
              username: "",
              display_name: "",
              assets: nil

    @type t :: [
            id: String.t(),
            asset_number: String.t(),
            serial_number: String.t(),
            assets: [Asset.t()] | [] | nil
          ]
  end

  defmodule Asset do
    alias PrintClient.AssetsApi.SearchResult.User

    defstruct id: "",
              asset_number: "",
              serial_number: "",
              owner: nil

    @type t :: [
            id: String.t(),
            asset_number: String.t(),
            serial_number: String.t(),
            owner: User.t()
          ]
  end

  defstruct api_module: nil,
            api_config: nil,
            results: [],
            query: ""

  @type t :: [
          api_module: ApiAdapter.t() | nil,
          api_config: Map.t() | nil,
          results: List.t(),
          query: String.t()
        ]
end
