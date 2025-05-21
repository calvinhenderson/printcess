defmodule PrintClient.AssetsApi.ApiAdapter.Iiq do
  @behaviour PrintClient.AssetsApi.ApiAdapter
  alias PrintClient.AssetsApi.SearchResult

  defstruct instance: nil, token: nil, product_id: ""

  @type t :: [instance: String.t() | nil, token: String.t() | nil, product_id: String.t() | nil]

  @finch PrintClient.Finch
  @max_results 20

  require Logger

  def search_assets(config, query, opts \\ []) do
    req =
      %{
        "Query" => query,
        "SearchOnlineSystemsOnly" => false,
        "SearchManufacturer" => false,
        "SearchRoom" => false,
        "SearchModelName" => false,
        "SearchAsset" => true,
        "SearchSerial" => true,
        "SearchAssetName" => true
      }
      |> Jason.encode!()

    with {:ok, %Finch.Response{} = resp} <-
           post(config, "/api/v1.0/assets/search?$s=#{@max_results}&$o=AssetTag&$d=ASC", req),
         {:ok, results} <- parse_api_resp(resp) do
      {:ok, results}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_users(config, query, opts \\ []) do
    req =
      %{
        "Query" => query,
        "Facets" => 4,
        "Limit" => @max_results
      }
      |> Jason.encode!()

    with {:ok, %Finch.Response{} = resp} <-
           post(config, "/api/v1.0/search", req),
         {:ok, results} <- parse_api_resp(resp) do
      {:ok, results}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def post(%{token: "" <> token} = config, api, body) do
    Finch.build(
      :post,
      api(config, api),
      [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"},
        {"productid", Map.get(config, :product_id, "")}
      ],
      body
    )
    |> dbg()
    |> Finch.request(@finch)
  end

  defp parse_api_resp(%Finch.Response{} = resp) do
    Jason.decode(resp.body)
    |> case do
      {:ok, %{"Items" => items}} ->
        items
        |> Enum.map(fn item ->
          api_object_to_search_result(item)
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()
        |> then(&{:ok, &1})

      {:ok, %{"Item" => %{"Users" => items}}} ->
        items
        |> Enum.map(fn item ->
          api_object_to_search_result(item)
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()
        |> then(&{:ok, &1})

      {:ok, %{"Item" => item}} ->
        item
        |> api_object_to_search_result()
        |> then(&{:ok, &1})

      {:error, reason} ->
        Logger.error("Iiq: error decoding API response. #{inspect(reason)}")
        {:error, reason}
    end
  end

  # defp parse_api_resp(%Finch.Response{} = resp) do
  #   Logger.error(
  #     "Iiq: non-okay response received. #{inspect(resp.status)} - #{inspect(resp.body)}"
  #   )
  #
  #   {:error, resp.status}
  # end

  defp api_object_to_search_result(item) do
    case item do
      %{"AssetId" => id, "AssetNumber" => asset, "SerialNumber" => serial} ->
        struct!(SearchResult.Asset,
          id: id,
          asset_number: asset,
          serial_number: serial,
          manufacturer: Map.get(asset, ["Model", "Manufacturer", "Name"], ""),
          model: Map.get(asset, ["Model", "Name"], "")
        )

      %{"UserId" => id, "Username" => username, "Name" => display_name} = user ->
        # Maybe strip the email suffix
        username = Regex.replace(~r/@[^@]*$/, username, "")

        struct!(SearchResult.User,
          id: id,
          username: username,
          display_name: display_name,
          grade: Map.get(user, "Grade")
        )

      unknown ->
        Logger.error("Iiq: unhandled API response received. #{inspect(unknown)}")
        nil
    end
  end

  defp api(%{instance: nil}, _api), do: raise("api instance not configured")
  defp api(%{instance: instance}, api), do: "https://#{instance}.incidentiq.com#{api}"
end
