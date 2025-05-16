defmodule PrintClientWeb.PrintComponents do
  use PrintClientWeb, :html

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
      class="flex flex-col gap-3 p-4 rounded-md border-zinc-200 border-2"
      disabled={@disabled}
    >
      <.label :if={@disabled}>Form is disabled. Please choose a printer and a template first.</.label>
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
end
