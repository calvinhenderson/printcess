defmodule PrintClient.AssetsApi.ApiAdapter.Mock do
  @behaviour PrintClient.AssetsApi.ApiAdapter
  alias PrintClient.AssetsApi.SearchResult

  defstruct instance: nil, token: nil, product_id: ""

  @type t :: [instance: String.t() | nil, token: String.t() | nil, product_id: String.t() | nil]

  require Logger

  def config(settings),
    do: %__MODULE__{
      instance: settings.instance,
      token: settings.token,
      product_id: settings.product_id
    }

  def search_assets(_config, _query, _opts \\ []) do
    results = [
      %SearchResult.Asset{
        id: "asset-id-001",
        asset: "A001",
        serial: "SN001",
        manufacturer: "Mock",
        model: "Asset",
        username: "user001"
      }
    ]

    {:ok, results}
  end

  def search_users(_config, _query, _opts \\ []) do
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
