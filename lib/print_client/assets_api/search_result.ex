defmodule PrintClient.AssetsApi.SearchResult do
  # --- SearchResult.User ---
  defmodule User do
    defstruct id: "",
              username: "",
              display_name: "",
              role: "",
              location: "",
              grade: ""

    @type t :: [
            id: String.t(),
            username: String.t(),
            display_name: String.t(),
            role: String.t() | nil,
            location: String.t() | nil,
            grade: String.t() | nil
          ]
  end

  # --- SearchResult.Asset ---
  defmodule Asset do
    defstruct id: "",
              manufacturer: "",
              model: "",
              asset: "",
              serial: "",
              status: "",
              location: "",
              username: ""

    @type t :: [
            id: String.t(),
            manufacturer: String.t() | nil,
            model: String.t() | nil,
            asset: String.t(),
            serial: String.t(),
            status: String.t() | nil,
            location: String.t() | nil,
            username: String.t() | nil
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
