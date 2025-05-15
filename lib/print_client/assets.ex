defmodule PrintClient.Assets do
  @moduledoc """
  Provides an API for interacting with remote assets.
  """

  @all_assets [
    %{
      "asset_number" => "10001",
      "serial_number" => "ABC1234",
      "owner_username" => "donald_trump"
    },
    %{
      "asset_number" => "10002",
      "serial_number" => "ZXV9830",
      "owner_username" => "kamala_harris"
    },
    %{
      "asset_number" => "10203",
      "serial_number" => "EFGH458",
      "owner_username" => "george_w_bush"
    }
  ]

  def search(query) when is_binary(query) do
    # Simulate the API call
    Process.sleep(50)

    query_low = String.downcase(query)

    @all_assets
    |> Enum.filter(fn asset ->
      String.contains?(String.downcase(asset["asset_number"]), query_low) or
        String.contains?(String.downcase(asset["serial_number"]), query_low) or
        String.contains?(String.downcase(asset["owner_username"]), query_low)
    end)
  end
end
