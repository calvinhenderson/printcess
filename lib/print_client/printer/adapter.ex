defprotocol PrintClient.Printer.Adapter do
  @doc "Establishes a connection to the printer."
  @spec connect(struct()) :: {:ok, struct()} | {:error, term()}
  def connect(config)

  @doc "Closes the connection to the printer."
  @spec disconnect(struct()) :: {:ok, struct()} | {:error, term()}
  def disconnect(config)

  @doc "Sends data to the printer."
  @spec print(struct(), term()) :: :ok | {:error, term(), struct()}
  def print(config, data)

  @doc "Checks the printer status."
  @spec status(struct()) :: :connected | :disconnected
  def status(config)

  @doc "Returns whether the printer is online."
  @spec online?(struct()) :: boolean()
  def online?(config)
end
