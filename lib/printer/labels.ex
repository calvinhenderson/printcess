defmodule PrintClient.Printer.Labels do
  @doc """
  Takes a map and converts it to a valid label struct.
  ## Returns

      {:ok, struct}

  or

      {:error, reason}

  on failure.

  ## Examples

    iex> Labels.map_to_struct(%{"asset" => "12345", "serial" => "9QV56N"})
    {:ok, %AssetLabel{asset: "12345", serial: "9QV56N", copies: 1}}
  """
  @spec validate_label_map(term) :: {:ok, term} | {:error, term}
  def validate_label_map(map) do
    data = map
    |> string_keys_to_atoms
    |> then(fn d -> if Map.has_key?(d, :copies) do
        d
      else
        Map.merge(%{copies: 1}, d)
      end
    end)

    if Map.has_key?(data, :text) or Map.has_key?(data, [:asset, :serial]) do
      {:ok, data}
    else
      {:error, :invalid_map_keys}
    end
  end

  defp string_keys_to_atoms(data) when is_map(data) do
    Map.new(data, fn {key, val} ->
      if is_atom(key) do
        {key, val}
      else
        {String.to_atom(key), val}
      end
    end)
  end
  defp string_keys_to_atoms(data), do: data
end
