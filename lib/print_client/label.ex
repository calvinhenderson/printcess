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
      serial: get_param(params, :serial)
    })
  end

  defp get_param(params, key, default \\ nil) when is_map(params) and is_atom(key),
    do: Map.get(params, key, default) || Map.get(params, Atom.to_string(key), default)
end
