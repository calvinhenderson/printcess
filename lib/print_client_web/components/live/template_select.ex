defmodule PrintClientWeb.TemplateSelectComponent do
  use PrintClientWeb, :live_component

  require Logger

  alias PrintClient.Label.Template
  import PrintClientWeb.PrintComponents

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(selected: nil)
      |> assign_templates()

    # send(self(), {:select_template, socket.assigns.templates |> Enum.at(0)})

    {:ok, socket}
  end

  @impl true
  attr :id, :string, required: true

  def render(assigns) do
    ~H"""
    <div id={@id} class="contents">
      <.dropdown results={@templates} class="rounded-l-md">
        <:label class="join">
          <div class="btn btn-soft join-item" role="button" tabindex="0">Templates</div>
          <span phx-target={@myself} phx-click="refresh" class="btn btn-soft join-item">
            <.icon name="hero-arrow-path" />
          </span>
        </:label>
        <:option :let={template}>
          <div phx-click="select" phx-target={@myself} phx-value-id={template.id} tabindex="0">
            {template.name}
          </div>
        </:option>
      </.dropdown>
    </div>
    """
  end

  @impl true
  def handle_event("select", %{"id" => template_id}, socket) do
    Logger.info("TemplateSelectComponent: selected #{inspect(template_id)}")

    send(
      self(),
      {:select_template, socket.assigns.templates |> Enum.find(&(&1.id == template_id))}
    )

    {:noreply,
     socket
     |> assign_selected(template_id)}
  end

  def handle_event("select", _params, socket), do: {:noreply, socket}

  def handle_event("refresh", _params, socket) do
    Logger.info("TemplateSelectComponent: refreshing templates")
    {:noreply, socket |> assign_templates()}
  end

  # --- Internal API ---

  defp assign_templates(socket) do
    templates = list_templates()

    socket
    |> assign(templates: templates)
  end

  defp assign_selected(%{assigns: %{templates: templates}} = socket, template_name),
    do: assign(socket, :selected, Enum.find(templates, &(&1.name == template_name)))

  defp list_templates, do: Template.load_templates()
end
