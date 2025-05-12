defmodule PrintClient.Label do
  @moduledoc """
  Provides an API for encoding label templates.
  """

  def render(template, assigns) do
    Phoenix.Template.render_to_string(__MODULE__, template, "html", assigns)
  end
end
