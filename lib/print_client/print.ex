defmodule PrintClient.Print do

  # Static asset files
  @asset_blank_path "priv/static/asset-blank.pcx"
  @text_font_path   "priv/static/text-font.ttf"

  require Logger

  @doc """
  Sends a print job to the printer.
  Running this before `init_job/2` will fail!
  """
  def print(printer, job_type, opts, copies \\ 1) do
    command = build_label_command(opts, copies)

    {:ok, socket} = init_job(printer, job_type)

    socket
    |> send_binary(command)
    |> end_job()
  end

  defp init_job(printer, job_type) do
    if not Map.has_key?(printer, :host) or not Map.has_key?(printer, :port) do
      raise "Missing :host or :port key in #{inspect printer}"
    end

    {:ok, socket} = :gen_tcp.connect(to_charlist(printer.host), printer.port, [:binary, active: false])

    prefetch_job_assets(socket, job_type)

    {:ok, socket}
  end

  defp end_job(socket) do
    :gen_tcp.close(socket)
  end

  defp send_binary(socket, command) do
    Logger.debug("Sending command: #{inspect command}")
    :gen_tcp.send(socket, command)
    socket
  end

  defp prefetch_job_assets(socket, job_type) do
    {file_name, data} = case job_type do
      :text ->
        {:ok, data} = File.read(Application.app_dir(:print_client, @text_font_path))
        {"LABELFONT.TTF", data}
      :asset ->
        {:ok, data} = File.read(Application.app_dir(:print_client, @asset_blank_path))
        Logger.debug("Uploading: #{inspect data}")
        {"ASSETBLANK.PCX", data}
      _ ->
        raise "Unknown job type given: #{inspect job_type}"
    end

    send_binary(socket, <<"DOWNLOAD F,\"#{file_name}\",#{byte_size(data)},">> <> data <> <<"\r\n">>)
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
      "BLOCK 0,100,1200,125,\"LABELFONT.TTF\",0,24,24,0,2,1,\"#{text}\"\r\n",
      "PRINT #{copies}\r\n"
    >>
  end

  defp build_label_command(%{asset: asset, serial: serial}, copies) do
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
      "BARCODE 360,424,\"128\",62,0,0,5,5,2,\"#{asset}\"\r\n",
      "BARCODE 882,424,\"128\",62,0,0,4,4,2,\"#{serial}\"\r\n",

      # Clear the space underneath the barcodes and write their values
      "ERASE 0,486,1200,26\r\n",
      "TEXT 360,490,\"1\",0,2,2,2,\"#{asset}\"\r\n",
      "TEXT 882,490,\"1\",0,2,2,2,\"#{serial}\"\r\n",
      "PRINT #{copies}\r\n",
      "EOP\r\n",

      ":BARCODE_SIZE\r\n",
    >>
  end

  defp build_label_command(opts, _), do: raise "Invalid label command options: #{inspect opts}"
end
