defmodule PrintClient.AssetsApi.ApiAdapter.Iiq do
  @behaviour PrintClient.AssetsApi.ApiAdapter
  alias PrintClient.AssetsApi.SearchResult

  defstruct instance: nil

  @type t :: [instance: String.t() | nil]

  def search_assets(config, query, opts) do
    with {:ok, %Finch.Response{} = resp} <- post("/api/v1.0/assets/search"),
         {:ok, results} <- parse_api_resp(resp) do
      {:ok, results}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_users(config, query, opts) do
  end

  defp post(config, api, body) do
    Finch.build(
      :post,
      api(api),
      %{
        "Content-Type" => "application/json",
        "productid" => config.productid
      },
      body
    )
    |> Finch.request()
  end

  defp parse_api_resp(%Finch.Response{status: status} = resp) when status in 200..299 do
    Jason.decode(resp.body)
    |> case do
      {:ok, %{"Items" => items}} ->
        items
        |> Enum.map([], fn item ->
          api_object_to_search_result(item)
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()
        |> then(&{:ok, &1})

      {:ok, %{"Item" => item}} ->
        item
        |> api_object_to_search_result(item)
        |> then(&{:ok, &1})

      {:error, reason} ->
        Logger.error("Iiq: error decoding API response. #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_api_resp(%Finch.Response{} = resp) do
    Logger.error(
      "Iiq: non-okay response received. #{inspect(resp.status)} - #{inspect(resp.body)}"
    )

    {:error, resp.status}
  end

  defp api_object_to_search_result(item) do
    case item do
      %{"AssetId" => id, "AssetNumber" => asset, "SerialNumber" => serial} ->
        asset =
          struct!(SearchResult.Asset, id: id, asset_number: asset, serial_number: serial)

        [asset | acc]

      %{"UserId" => id, "Username" => username, "DisplayName" => display_name} ->
        user =
          struct!(SearchResult.User, id: id, username: username, display_name: display_name)

        [user | acc]

      unknown ->
        Logger.error("Iiq: unhandled API response received. #{inspect(unknown)}")
        nil
    end
  end

  defp api(%{instance: nil}, _api), do: raise("api instance not configured")
  defp api(%{instance: instance}, api), do: "https://#{instance}.incidentiq.com#{api}"
end
