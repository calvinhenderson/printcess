defmodule PrintClient.AssetsApi.ApiAdapter.Mock do
  @behaviour PrintClient.AssetsApi.ApiAdapter
  alias PrintClient.AssetsApi.SearchResult

  defstruct instance: nil, token: nil, product_id: ""

  @type t :: [instance: String.t() | nil, token: String.t() | nil, product_id: String.t() | nil]

  require Logger

  def search_assets(config, query, opts \\ []) do
    results = [
      %SearchResult.Asset{
        id: "asset-id-001",
        asset_number: "A001",
        serial_number: "SN001",
        manufacturer: "Mock",
        model: "Asset"
      }
    ]

    {:ok, results}
  end

  def search_users(config, query, opts \\ []) do
    results = [
      %SearchResult.User{
        id: "user-id-001",
        display_name: "User 001",
        username: "user001",
        grade: "1"
      }
    ]

    {:ok, results}
  end

  defp load_fixture(path) do
    full_path = Path.join("test/support/fixtures", path)

    Application.app_dir(:print_client, full_path)
    |> File.read!()
  end
end
