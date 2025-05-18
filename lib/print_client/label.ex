defmodule PrintClient.Label do
  @moduledoc """
  Provides an API for encoding label templates.
  """

  alias PrintClient.Label.Template

  require Logger

  @supported_protocols [:tspl]
  @type printer_protocol :: :tspl

  @doc """
  Renders the specified template with the specified params.

  ### Returns
  The rendered SVG data.
  """
  @spec render(Template.t(), Map.t()) :: binary()
  def render(%Template{} = template, params) when is_map(params) do
    params =
      Enum.reduce(template.required_fields, %{}, fn field, acc ->
        val = get_param(params, field)

        acc
        |> Map.put("#{field}", val)
        |> Map.put("#{field}_qr", render_qr_code(val))
      end)

    Mustache.render(template.template, params)
  end

  defp get_param(params, key, default \\ nil)

  defp get_param(params, key, default) when is_map(params) and is_atom(key),
    do: Map.get(params, key, default) || Map.get(params, Atom.to_string(key), default)

  defp render_qr_code(data) do
    with false <- is_nil(data),
         {:ok, qrcode} <-
           data
           |> QRCode.create(:high)
           |> QRCode.render(:svg, %QRCode.Render.SvgSettings{scale: 50, quiet_zone: 1}),
         encoded <- Base.encode64(qrcode, padding: true) do
      encoded
    else
      true ->
        ""

      error ->
        Logger.warning("Label: error while rendering qr code for template #{inspect(error)}.")
        ""
    end
  end

  @doc """
  Encodes the rendered template into a printer-specific protocol.
  """
  @spec encode(printer_protocol, binary(), Keyword.t()) :: {:ok, binary()} | {:error, term()}
  def encode(protocol, image, opts \\ [])

  def encode(:tspl, image, opts) when is_binary(image) do
    file = random_str()
    copies = Keyword.get(opts, :copies, 1)
    dpi = Keyword.get(opts, :dpi, 300)

    with :ok <- File.write("/tmp/#{file}.svg", image) do
      %Mogrify.Image{} =
        img = Mogrify.open("/tmp/#{file}.svg")

      img =
        img
        |> Mogrify.format("BMP")

      Mogrify.save(img, path: "/tmp/#{file}.bmp")
      Mogrify.save(img, path: "./#{file}.bmp")

      %{width: width, height: height} = Mogrify.identify("/tmp/#{file}.bmp")

      {:ok, bmp} = File.read("/tmp/#{file}.bmp")
      File.rm("/tmp/#{file}.svg")
      File.rm("/tmp/#{file}.bmp")

      dbg({width, dpi})
      dbg({height, dpi})

      {:ok,
       [
         <<"SIZE #{width / dpi} in, #{height / dpi} in\r\n">>,
         <<"DOWNLOAD \"#{file}\",#{byte_size(bmp)},", bmp::binary, "\r\n">>,
         <<"PUTBMP 0,0, \"#{file}\",,100\r\n">>,
         <<"PRINT #{copies}\r\n">>,
         <<"KILL \"#{file}\"\r\n">>,
         <<"END\r\n">>
       ]
       |> :binary.list_to_bin()}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def encode(protocol, _image, _opts) when protocol in @supported_protocols,
    do: {:error, :no_image}

  def encode(protocol, _template, _opts), do: raise("unsupported protocol: #{inspect(protocol)}")

  @random_chars "0123456789ABCDEFGHIMNOPQRSTUVWXYZabcdefghimnopqrstuvwxyz"
  def random_str(len \\ 8) when len > 0,
    do:
      for(
        _ <- 1..len,
        into: "",
        do: <<@random_chars |> String.to_charlist() |> Enum.random()>>
      )
end
