defmodule PrintClient.AssetsApi.SearchResult do
  # --- SearchResult.User ---
  defmodule User do
    defstruct id: "",
              username: "",
              display_name: "",
              grade: ""

    @type t :: [
            id: String.t(),
            username: String.t(),
            display_name: String.t(),
            grade: String.t()
          ]
  end

  # --- SearchResult.Asset ---
  defmodule Asset do
    alias PrintClient.AssetsApi.SearchResult.User

    defstruct id: "",
              manufacturer: "",
              model: "",
              asset_number: "",
              serial_number: "",
              owner: nil

    @type t :: [
            id: String.t(),
            manufacturer: String.t(),
            model: String.t(),
            asset_number: String.t(),
            serial_number: String.t(),
            owner: User.t()
          ]
  end

  # --- SearchResult ---

  alias PrintClient.AssetsApi.ApiAdapter

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
