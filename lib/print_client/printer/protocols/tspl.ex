defmodule PrintClient.Printer.Protocol.Tspl do
  @moduledoc """
  Provides an interface to a printer supporting TSPL2.
  """
  alias PrintClient.Printer.Adapter

  @doc """
  Checks if a printer is ready to receive a job
  """
  @spec ready?(Adapter.t(), pid()) :: true | false
  def ready?(adapter, pid) do
    ready = 0x00

    with :ok <- adapter.write(pid),
         :ok <- adapter.write(pid, <<27, "!?">>),
         {:ok, packet} <- adapter.read(pid),
         # Make sure we receive a proper ready response
         ^ready <- packet do
      true
    else
      error ->
        false
    end
  end

  @doc """
  Forcibly cancels all running jobs.
  """
  @spec cancel_all(Adapter.t(), pid()) :: :ok || {:error, term()}
  def cancel_all(adapter, pid) do
    adapter.write(pid, <<27, "!.">>)
  end

  @doc """
  Uploads a file to the printer's memory.

  Care should be taken to not upload too often, as this may prematurely wear out the eeprom.
  """
  @spec upload(Adapter.t(), pid(), socket(), binary(), binary()) ::
          {:ok, binary()} || {:error, term()}
  def upload(pid, name, path) when is_binary(name) and is_binary(path) do
    with assets_path <- Application.app_dir(:print_client, "priv/static"),
         full_path <- Path.join(assets_path, path),
         {:ok, data} <- File.read(full_path) do
      adapter.write(pid, <<
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
