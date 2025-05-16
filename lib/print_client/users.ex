defmodule PrintClient.Users do
  @moduledoc """
  Provides an API for interacting with remote users.
  """

  @all_users [
    %{
      "UserId" => "U1000",
      "Username" => "donald_trump",
      "FirstName" => "Donald",
      "LastName" => "Trump",
      "DisplayName" => "Donald Trump"
    },
    %{
      "UserId" => "U1000",
      "Username" => "kamala_harris",
      "FirstName" => "Kamala",
      "LastName" => "Harris",
      "DisplayName" => "Kamala Harris"
    },
    %{
      "UserId" => "U1000",
      "Username" => "george_w_bush",
      "FirstName" => "George",
      "LastName" => "Bush",
      "DisplayName" => "George W. Bush"
    }
  ]

  def search(query) when is_binary(query) do
    query_low = String.downcase(query)

    @all_users
    |> Enum.filter(fn user ->
      String.contains?(String.downcase(user["Username"]), query_low) or
        String.contains?(String.downcase(user["FirstName"]), query_low) or
        String.contains?(String.downcase(user["LastName"]), query_low) or
        String.contains?(String.downcase(user["DisplayName"]), query_low)
    end)
  end
end
