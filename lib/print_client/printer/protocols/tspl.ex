defmodule PrintClient.Printer.Protocol.Tspl do
  @moduledoc """
  Provides an interface to a printer supporting TSPL2.
  """
  alias PrintClient.Printer.Adapter

  @doc """
  Checks if a printer is ready to receive a job
  """
  @spec ready?(Adapter.t(), term()) :: true | false
  def ready?(adapter, socket \\ nil) do
    with {:ok, socket} <- adapter.send(printer),
         {:ok, socket} <- adapter.send(socket, <<27, "!?">>),
         {:ok, packet} <- adapter.recv(socket),
         # Make sure we receive a proper ready response
         ^0x00 <- packet do
      true
    else
      error ->
        false
    end
  end

  @doc """
  Forcibly cancels all running jobs.
  """
  @spec cancel_all(Adapter.t()) :: :ok || {:error, term()}
  def cancel_all(adapter) do
    adapter.send(adapter, <<27, "!.">>)
  end

  @doc """
  Uploads a file to the printer's memory.

  Care should be taken to not upload too often, as this may prematurely wear out the eeprom.
  """
  @spec upload(Adapter.t(), socket(), binary(), binary()) :: {:ok, binary()} || {:error, term()}
  def upload(adapter, name, path) when socket: socket() and is_binary(name) and is_binary(path) do
    with assets_path <- Application.app_dir(:print_client, "priv/static"),
         full_path <- Path.join(assets_path, path),
         {:ok, data} <- File.read(full_path) do
      adapter.send(<<
        "DOWNLOAD F,",
        "\"#{file_name}\",",
        "#{byte_size(data)},",
        data,
        "\r\n"
      >>)
    else
      error -> error
    end
  end
end
