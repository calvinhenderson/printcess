defmodule PrintClient.Printer do
  # Static asset files
  @asset_blank_path "priv/static/asset-blank.pcx"
  @text_font_path "priv/static/text-font.ttf"

  require Logger

  @doc """
  Checks if a printer is ready to receive a job
  """
  def ready?(printer) do
    case open_job(printer) do
      {:ok, socket} ->
        send_binary(socket, <<27, "!S">>)
        {:ok, packet} = read_binary(socket, 8)

        ready_status = packet == <<0x02, 0x40, 0x40, 0x40, 0x40, 0x03, 0x0D, 0x0A>>

        end_job(socket)

        ready_status

      _error ->
        false
    end
  end

  @doc """
  Sends a print job to the printer.
  """
  def print(%{printer: printer, asset: asset, serial: serial, copies: copies}) do
    print_opts(printer, :asset, %{asset: asset, serial: serial}, copies)
  end

  def print(%{printer: printer, text: text, copies: copies}) do
    print_opts(printer, :text, %{text: text}, copies)
  end

  defp print_opts(printer, job_type, opts, copies) do
    command = build_label_command(opts, copies)

    case init_job(printer, job_type) do
      {:ok, socket} ->
        socket
        |> send_binary(command)
        |> end_job()

      error ->
        error
    end
  end

  defp init_job(printer, job_type) do
    case open_job(printer) do
      {:ok, socket} ->
        prefetch_job_assets(socket, job_type)
        {:ok, socket}

      error ->
        error
    end
  end

  defp open_job(printer) do
    if not Map.has_key?(printer, :hostname) or not Map.has_key?(printer, :port) do
      raise "Missing :hostname or :port key in #{inspect(printer)}"
    end

    :gen_tcp.connect(to_charlist(printer.hostname), printer.port, [
      :binary,
      active: false
    ])
  end

  defp end_job(socket) do
    :gen_tcp.close(socket)
  end

  defp send_binary(socket, command) do
    Logger.debug("Sending command: #{inspect(command)}")
    :gen_tcp.send(socket, command)
    socket
  end

  defp read_binary(socket, length) do
    :gen_tcp.recv(socket, length)
  end

  defp prefetch_job_assets(socket, job_type) do
    {file_name, data} =
      case job_type do
        :text ->
          {:ok, data} = File.read(Application.app_dir(:print_client, @text_font_path))
          {"LABELFONT.TTF", data}

        :asset ->
          {:ok, data} = File.read(Application.app_dir(:print_client, @asset_blank_path))
          Logger.debug("Uploading: #{inspect(data)}")
          {"ASSETBLANK.PCX", data}
      end

    send_binary(
      socket,
      <<"DOWNLOAD F,\"#{file_name}\",#{byte_size(data)},">> <> data <> <<"\r\n">>
    )
  end

  defp get_barcode_size(len) do
    a = String.length(len)

    Enum.min([
      5,
      Enum.max([
        2,
        :math.floor((10 - a / 2 + 0.5) * 0.7)
      ])
    ])
  end

  defp build_label_command(%{text: text}, copies) do
    <<
      "SIZE 1200 dot,225 dot\r\n",
      "SPEED 2\r\n",
      "DENSITY 8\r\n",
      "OFFSET 0,0\r\n",
      "GAP 0,0\r\n",
      "DIRECTION 1\r\n",
      "CLS\r\n",
      "BLOCK 40,55,1100,125,\"LABELFONT.TTF\",0,28,28,0,2,1,\"#{text}\"\r\n",
      "PRINT #{copies}\r\n"
    >>
  end

  defp build_label_command(%{asset: asset, serial: serial}, copies) do
    asset_size = get_barcode_size(asset)
    serial_size = get_barcode_size(serial)

    <<
      # Setup
      "SIZE 1200 dot,600 dot\r\n",
      "SPEED 2\r\n",
      "DENSITY 8\r\n",
      "OFFSET 0,0\r\n",
      "GAP 0,0\r\n",
      "REFERENCE 0,0\r\n",
      "DIRECTION 1\r\n",
      "CLS\r\n",

      # Draw blank asset label
      "PUTPCX 0,0,\"ASSETBLANK.PCX\"\r\n",
      "REVERSE 0,0,1200,600\r\n",

      # Draw barcodes
      "BARCODE 360,424,\"128\",62,0,0,#{asset_size},#{asset_size},2,\"#{asset}\"\r\n",
      "BARCODE 882,424,\"128\",62,0,0,#{serial_size},#{serial_size},2,\"#{serial}\"\r\n",

      # Clear the space underneath the barcodes and write their values
      "ERASE 0,486,1200,26\r\n",
      "TEXT 360,490,\"1\",0,2,2,2,\"#{asset}\"\r\n",
      "TEXT 882,490,\"1\",0,2,2,2,\"#{serial}\"\r\n",
      "PRINT #{copies}\r\n",
      "EOP\r\n",
      ":BARCODE_SIZE\r\n"
    >>
  end

  defp build_label_command(opts, _),
    do: raise("Invalid label command options: #{inspect(opts)}")
end
