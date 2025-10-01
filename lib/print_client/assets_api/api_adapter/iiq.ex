defmodule PrintClient.AssetsApi.ApiAdapter.Iiq do
  @behaviour PrintClient.AssetsApi.ApiAdapter
  alias PrintClient.AssetsApi.SearchResult

  defstruct instance: nil, token: nil, product_id: ""

  @type t :: [instance: String.t() | nil, token: String.t() | nil, product_id: String.t() | nil]

  @finch PrintClient.Finch
  @max_results 20

  require Logger

  def config(settings),
    do: %__MODULE__{
      instance: settings.instance,
      token: settings.token,
      product_id: settings.product_id
    }

  def search_assets(config, query, opts \\ []) when is_binary(query) do
    req =
      %{
        "Query" => query,
        "SearchOnlineSystemsOnly" => false,
        "SearchManufacturer" => false,
        "SearchRoom" => false,
        "SearchModelName" => false,
        "SearchName" => true,
        "SearchAsset" => true,
        "SearchSerial" => true,
        "SearchAssetName" => true
      }
      |> Jason.encode!()

    with {:ok, %Finch.Response{} = resp} <-
           post(config, "/api/v1.0/search?$s=#{@max_results}&$o=AssetTag&$d=ASC", req),
         {:ok, results} <- parse_api_resp(resp) do
      {:ok, results}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def search_users(config, query, opts \\ []) when is_binary(query) do
    req =
      %{
        "Query" => query,
        "Limit" => @max_results
      }
      |> Jason.encode!()

    with {:ok, %Finch.Response{} = resp} <-
           post(config, "/api/v1.0/search?$s=#{@max_results}&$o=FirstName&$d=ASC", req),
         {:ok, results} <- parse_api_resp(resp) do
      {:ok, results}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def post(%{token: "" <> token} = config, api, body) do
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    headers =
      if config.product_id == nil or config.product_id == "",
        do: headers,
        else: [{"productid", config.product_id} | headers]

    Finch.build(
      :post,
      api(config, api),
      headers,
      body
    )
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

      {:ok, %{"Item" => %{} = item}} ->
        if Map.has_key?(item, "Users") or Map.has_key?(item, "Assets") do
          (Map.get(item, "Users", []) ++ Map.get(item, "Assets", []))
          |> Enum.map(fn item ->
            api_object_to_search_result(item)
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.reverse()
        else
          item
          |> api_object_to_search_result()
        end
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
      %{"AssetId" => id, "AssetTag" => asset_number, "SerialNumber" => serial_number} = asset ->
        username =
          get_in(asset, ["Owner", "Username"])
          |> then(
            &case &1 do
              "" <> username ->
                Regex.replace(~r/@[^@]*$/, username, "")

              nil ->
                ""
            end
          )

        struct!(SearchResult.Asset,
          id: id,
          asset: asset_number,
          serial: serial_number,
          manufacturer: get_in(asset, ["Model", "Manufacturer", "Name"]),
          model: get_in(asset, ["Model", "ModelName"]),
          status: get_in(asset, ["Status", "Name"]),
          location: get_in(asset, ["Location", "Name"]),
          username: username
        )

      %{"UserId" => id, "Username" => username, "Name" => display_name} = user ->
        # Maybe strip the email suffix
        username = Regex.replace(~r/@[^@]*$/, username, "")

        struct!(SearchResult.User,
          id: id,
          username: username,
          display_name: display_name,
          role: get_in(user, ["Role", "Name"]),
          location: get_in(user, ["Location", "Name"]),
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
