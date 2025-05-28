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
    defstruct id: "",
              manufacturer: "",
              model: "",
              asset: "",
              serial: "",
              username: ""

    @type t :: [
            id: String.t(),
            manufacturer: String.t(),
            model: String.t(),
            asset: String.t(),
            serial: String.t(),
            username: String.t()
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
