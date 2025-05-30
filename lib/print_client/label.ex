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
  def render(%Template{} = template, %{} = params) do
    params =
      Enum.reduce(template.required_fields, %{}, fn field, acc ->
        val = get_param(params, field)

        acc
        |> Map.put("#{field}", val)
        |> Map.put("#{field} qrcode", render_qr_code(val))
      end)

    render_template(template.template, params)
  end

  def render(%Template{} = template, nil) do
    render_template(template.template, %{})
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
      "data:image/svg+xml;base64," <> encoded
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
        img =
        "/tmp/#{file}.svg"
        |> Mogrify.open()
        |> Mogrify.custom("alpha", "off")
        |> Mogrify.custom("depth", "1")
        |> Mogrify.custom("type", "bilevel")
        |> Mogrify.custom("density", "200")
        |> Mogrify.custom("units", "pixelsperinch")
        |> Mogrify.custom("negate")
        |> Mogrify.format("PCX")

      Mogrify.save(img, path: "/tmp/#{file}.pcx")

      %{width: width, height: height} = Mogrify.identify("/tmp/#{file}.pcx")

      {:ok, img} = File.read("/tmp/#{file}.pcx")
      File.rm("/tmp/#{file}.svg")
      File.rm("/tmp/#{file}.pcx")

      {:ok,
       [
         <<"SIZE #{width / dpi},#{height / dpi}\r\n">>,
         <<"CLS\r\n">>,
         <<"DIRECTION 1,0\r\n">>,
         <<"DOWNLOAD \"#{file}\",#{byte_size(img)},", img::binary, "\r\n">>,
         <<"PUTPCX 0,0, \"#{file}\"\r\n">>,
         <<"PRINT #{copies}\r\n">>,
         <<"KILL \"#{file}\"\r\n">>
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

  # @random_chars "0123456789ABCDEFGHIMNOPQRSTUVWXYZ"
  @random_chars "ABCDEFGHIMNOPQRSTUVWXYZ" |> String.downcase()
  defp random_str(len \\ 4) when len > 0,
    do:
      for(
        _ <- 1..len,
        into: "",
        do: <<@random_chars |> String.to_charlist() |> Enum.random()>>
      )

  def render_template(template, params) do
    Regex.replace(~r/{{\s*(\w+)\s*(\[[^\]]+\])?\s*}}/, template, fn _match, var, opts ->
      case Map.get(params, var, "") do
        "" <> val -> val
        _ -> ""
      end
    end)
  end
end
