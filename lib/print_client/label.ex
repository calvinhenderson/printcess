defmodule PrintClient.Label do
  @moduledoc """
  Provides an API for encoding label templates.
  """

  alias PrintClient.Label.Template

  @spec render(Template.t(), Map.t()) :: binary()
  def render(%Template{} = template, params) when is_map(params) do
    Mustache.render(template.template, %{
      username: get_param(params, :username),
      asset: get_param(params, :asset),
      serial: get_param(params, :serial),
      copies: get_param(params, :copies)
    })
    |> render_qr_code("asset_qr")
    |> render_qr_code("serial_qr")
    |> to_tspl()
  end

  defp get_param(params, key, default \\ nil) when is_map(params) and is_atom(key),
    do: Map.get(params, key, default) || Map.get(params, Atom.to_string(key), default)

  defp render_qr_code(template, id) do
    id
    |> qr_code_expr()
    |> Regex.scan(template)
    |> Enum.reduce(template, fn match ->
      dbg(match)
    end)
  end

  defp qr_code_expr(id), do: ~r|<rect[^>]id="#{id}"[^>]/>|

  defp to_tspl(template) do
    template
  end
end
