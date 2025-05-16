defmodule PrintClient.Assets do
  @moduledoc """
  Provides an API for interacting with remote assets.
  """

  @all_assets [
    %{
      "AssetId" => "A1000",
      "AssetNumber" => "10001",
      "SerialNumber" => "ABC1234",
      "OwnerEmail" => "donald_trump"
    },
    %{
      "AssetId" => "A1000",
      "AssetNumber" => "10002",
      "SerialNumber" => "ZXV9830",
      "OwnerEmail" => "kamala_harris"
    },
    %{
      "AssetId" => "A1000",
      "AssetNumber" => "10203",
      "SerialNumber" => "EFGH458",
      "OwnerEmail" => "george_w_bush"
    }
  ]

  def search(query) when is_binary(query) do
    # Simulate the API call
    Process.sleep(50)

    query_low = String.downcase(query)

    @all_assets
    |> Enum.filter(fn asset ->
      String.contains?(String.downcase(asset["AssetNumber"]), query_low) or
        String.contains?(String.downcase(asset["SerialNumber"]), query_low) or
        String.contains?(String.downcase(asset["OwnerEmail"]), query_low)
    end)
  end
end
