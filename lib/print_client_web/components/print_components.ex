defmodule PrintClientWeb.PrintComponents do
  use PrintClientWeb, :html

  alias PrintClient.Label

  @doc """

  """
  attr :label, :string, required: true, doc: "the dropdown button text"
  attr :options, :list, default: []
  attr :side, :string, default: "start"
  attr :class, :string, default: ""
  attr :rest, :global
  slot :inner_block

  def dropdown(assigns) do
    ~H"""
    <div class={"dropdown dropdown-#{@side}"} {@rest}>
      <div tabindex="0" role="button" class={["btn btn-bordered", @class]}>{@label}</div>
      <ul
        tabindex="0"
        class="menu dropdown-content bg-base-200 rounded-box z-1 mt-4 w-52 p-2 shadow-sm"
      >
        <li :for={row <- @options}>{render_slot(@inner_block, row)}</li>
      </ul>
    </div>
    """
  end

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
    <div>
      <.header>{@title}</.header>
      <.form
        :let={f}
        for={@for}
        id={@id}
        phx-submit={@submit}
        phx-change={@change}
        phx-debounce="250"
        class="flex flex-col gap-3"
        disabled={@disabled}
      >
        <.input
          field={f[:username]}
          name="username"
          type="text"
          label="Username"
          placeholder="john_doe"
          disabled={@disabled or :username not in @required}
          id={@id <> "-username"}
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

        <.button type="submit" class="mt-4" disabled={@disabled} phx-disable-with="Submitting..">
          Submit
        </.button>
      </.form>
    </div>
    """
  end

  @doc """
  Renders a label template with the specified params.
  """

  attr :template, :map, required: true
  attr :params, :map, default: %{}

  def label_template(assigns) do
    ~H"""
    <div
      :if={not is_nil(@template)}
      class="flex flex-col justify-center items-center w-full h-full max-w-full max-h-[100pt] border-2 border-gray-200 rounded-md mx-auto"
    >
      {raw(Label.render(@template, @params))}
    </div>
    """
  end
end
