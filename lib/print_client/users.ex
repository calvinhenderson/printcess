defmodule PrintClient.Users do
  @moduledoc """
  Provides an API for interacting with remote users.
  """

  @all_users [
    %{
      "username" => "donald_trump",
      "given_name" => "Donald",
      "family_name" => "Trump",
      "display_name" => "Donald Trump"
    },
    %{
      "username" => "kamala_harris",
      "given_name" => "Kamala",
      "family_name" => "Harris",
      "display_name" => "Kamala Harris"
    },
    %{
      "username" => "george_w_bush",
      "given_name" => "George",
      "family_name" => "Bush",
      "display_name" => "George W. Bush"
    }
  ]

  def search(query) when is_binary(query) do
    query_low = String.downcase(query)

    @all_users
    |> Enum.filter(fn user ->
      String.contains?(String.downcase(user["username"]), query_low) or
        String.contains?(String.downcase(user["given_name"]), query_low) or
        String.contains?(String.downcase(user["family_name"]), query_low) or
        String.contains?(String.downcase(user["display_name"]), query_low)
    end)
  end
end
