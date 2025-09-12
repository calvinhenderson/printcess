defprotocol PrintClient.Label.Encoder do
  @doc "Encodes a label template."
  @spec encode(binary(), List.t()) :: {:ok, term()} | {:error, term()}
  def encode(image, opts \\ [])
end
