defmodule PrintClient.Label do
  @moduledoc """
  Provides an API for encoding label templates.
  """

  alias PrintClient.Label.Template

  require Logger

  @encoder_modules %{
    "tspl" => PrintClient.Label.Encoder.TSPL
  }
  @supported_encoders Map.keys(@encoder_modules)

  @doc """
  Returns a list of supported encoders.
  """
  def list_encoders, do: @encoder_modules

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
  Lists available encodings.
  """
  @spec list_encodings :: [atom()]
  def list_encodings, do: @supported_encoders

  @doc """
  Encodes the rendered template into a printer-preferred encoding.
  """
  @spec encode(binary(), binary(), Keyword.t()) :: {:ok, binary()} | {:error, term()}
  def encode(encoder, image, opts) when encoder in @supported_encoders do
    mod = Map.get(@encoder_modules, encoder)
    apply(mod, :encode, [image, opts])
  end

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
