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
  @spec render(Template.t(), map()) :: binary()
  def render(%Template{} = template, params \\ nil) do
    render_template(template.template, params, template.fields)
  end

  defp get_param(params, key, default) when is_map(params) and is_atom(key),
    do: Map.get(params, key, default) || Map.get(params, Atom.to_string(key), default)

  defp render_qr_code(data) when is_nil(data) or data == "", do: ""

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

  def render_template(template, nil, fields), do: render_template(template, %{}, fields)

  def render_template(template, form_params, fields) do
    Enum.reduce(fields, template, fn {raw, {field, field_params}}, template ->
      param = get_param(form_params, field, "")

      # TODO: add more supported params here
      replacement =
        cond do
          is_nil(field_params) -> param
          String.contains?(field_params, "qrcode") -> render_qr_code(param)
          true -> param
        end

      String.replace(template, raw, replacement, global: true)
    end)
  end
end
