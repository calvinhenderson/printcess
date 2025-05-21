defmodule PrintClientWeb.TemplateSelectComponent do
  use PrintClientWeb, :live_component

  require Logger

  alias PrintClient.Label.Template

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(selected: nil)
      |> assign_templates()

    # if Mix.env() in [:dev, :test],
    #   do: send(self(), {:select_template, socket.assigns.templates |> Enum.at(0)})

    {:ok, socket}
  end

  @impl true
  def handle_event("select", %{"select" => template_name}, socket) do
    Logger.info("TemplateSelectComponent: selected #{inspect(template_name)}")

    send(
      self(),
      {:select_template, socket.assigns.templates |> Enum.find(&(&1.name == template_name))}
    )

    {:noreply,
     socket
     |> assign_selected(template_name)}
  end

  @impl true
  def handle_event("select", _, socket), do: {:noreply, socket}

  def handle_event("refresh", _params, socket) do
    Logger.info("TemplateSelectComponent: refreshing templates")

    send(self(), {:select_template, nil})

    {:noreply, socket |> assign_templates() |> assign(selected: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-4">
      <form id={@id <> "-form"} phx-change="select" phx-target={@myself}>
        <.input
          id={@id <> "-select"}
          name="select"
          type="select"
          options={@template_options}
          disabled={@selected != nil}
        />
      </form>
      <.button phx-target={@myself} phx-click="refresh">
        <.icon name={if @selected == nil, do: "hero-arrow-path", else: "hero-trash"} />
      </.button>
    </div>
    """
  end

  defp assign_templates(socket) do
    templates = list_templates()

    template_options =
      templates
      |> Enum.reduce([], fn template, acc ->
        [{template.name, template.name} | acc]
      end)
      |> Enum.reverse()

    socket
    |> assign(templates: templates)
    |> assign(template_options: template_options)
  end

  defp assign_selected(%{assigns: %{templates: templates}} = socket, template_name),
    do: assign(socket, :selected, Enum.find(templates, &(&1.name == template_name)))

  defp list_templates, do: Template.load_templates()

  defp _list_templates,
    do: [
      %Template{
        name: "Combined Chromebook Label",
        template:
          "SIZE 1200 dot, 375 dot\r\n" <>
            "DIRECTION 1\r\n" <>
            "CLS\r\n" <>
            "TEXT 10,10,\"4\",0,1,1,\"{{username}}\"\r\n" <>
            "BARCODE 100,60,\"128\",90,1,0,2,2,0, \"{{asset}}\"" <>
            "BARCODE 200,120, \"128\",90,1,0,2,2,0, \"{{serial}}\"\r\n" <>
            "PRINT {{copies}}\r\n" <>
            "END\r\n",
        # template: """
        #   <h1>Combined Chromebook Label</h1>
        #   <p>Asset: {{ asset_number }}</p>
        #   <p>Serial: {{ serial_number }}</p>
        #   <p>Owner: {{ username }}</p>
        # """,
        required_fields: [:username, :asset, :serial]
      }
    ]
end
