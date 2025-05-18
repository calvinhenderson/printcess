defmodule PrintClientWeb.PrintComponents do
  use PrintClientWeb, :html

  alias PrintClient.Label

  @doc """
  Renders a form for printing assets.
  """
  attr :id, :any, required: true
  attr :title, :string, default: "Label Form", doc: "the label form title"
  attr :for, :any, required: true, doc: "the form changeset"
  attr :submit, :string, default: "label_form-submit", doc: "the form submit event"
  attr :required, :list, default: []
  attr :disabled, :boolean, default: false, doc: "whether the form should be disabled"

  def label_form(assigns) do
    ~H"""
    <.header>{@title}</.header>
    <.form
      :let={f}
      for={@for}
      id={@id}
      phx-submit={@submit}
      phx-change={@change}
      phx-debounce="250"
      class="flex flex-col gap-3 rounded-md border-zinc-200 border-2"
      disabled={@disabled}
    >
      <.input
        field={f[:username]}
        name="username"
        type="text"
        label="Username"
        placeholder="john_doe"
        disabled={@disabled or :username not in @required}
      />
      <.input
        field={f[:asset]}
        name="asset"
        type="text"
        label="Asset Number"
        placeholder="00000"
        disabled={@disabled or :asset not in @required}
      />
      <.input
        field={f[:serial]}
        name="serial"
        type="text"
        label="Serial Number"
        placeholder="000000"
        disabled={@disabled or :serial not in @required}
      />
      <.input
        field={f[:copies]}
        name="copies"
        type="number"
        label="Copies"
        placeholder="1"
        disabled={@disabled}
      />

      <.button type="submit" class="mt-4" disabled={@disabled}>Submit</.button>
    </.form>
    """
  end

  @doc """
  Renders a label template with the specified params.
  """

  attr :template, :map, required: true
  attr :params, :map, default: %{}

  def label_template(assigns) do
    ~H"""
    <div :if={not is_nil(@template)} class="flex flex-col justify-center items-center w-100 h-100">
      {raw(Label.render(@template, @params))}
    </div>
    """
  end
end
