defmodule PrintClientWeb.TemplatesLive do
  use PrintClientWeb, :live_view

  alias PrintClient.{Label, Settings}

  require Logger

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_templates()}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-16">
        <div>
          <.header>Available Templates</.header>
          <ul class="list space-y-8">
            <li
              :for={t <- @templates}
              class={[
                "list-col card bg-base-100 border-2 shadow-md cursor-pointer",
                t.selected && "border-primary",
                not t.selected && "border-base-200"
              ]}
              phx-click="select"
              phx-value-id={t.id}
            >
              <div class="card-body">
                <p class="card-title text-lg font-heavy tracking-wide">{t.name}</p>
                <div class="flex flex-row gap-4">
                  <img
                    class="dark:invert bg-white text-black max-w-60 w-full rounded-box border-2 border-base-300"
                    src={
                      t.template
                      |> Base.encode64(padding: false)
                      |> then(&"data:image/svg+xml;base64,#{&1}")
                    }
                  />
                  <div>
                    <p class="text-xs opacity-60 tracking-wide pb-2">Form Fields</p>
                    <p class="flex flex-row flex-wrap gap-2">
                      <span :for={f <- t.form_fields} class="badge badge-ghost text-base-content/60">
                        {f}
                      </span>
                    </p>
                  </div>
                </div>
                <div :if={t.selected} class="card-actions justify-end">
                  <.button variant="outline"><.icon name="hero-pencil" />Edit</.button>
                  <.button variant="outline"><.icon name="hero-trash" />Delete</.button>
                </div>
              </div>
            </li>
          </ul>
        </div>

        <div>
          <.header>Search Paths</.header>
          <ul class="list">
            <li :for={l <- @locations} class="list-row items-center">
              <div><.icon name="hero-folder" /></div>
              <div>
                <p>{l.path}</p>
              </div>
              <.button variant="outline"><.icon name="hero-pencil" /></.button>
              <.button variant="outline"><.icon name="hero-trash" /></.button>
            </li>
          </ul>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select", %{"id" => selection_id}, socket) do
    templates =
      socket.assigns.templates
      |> Enum.map(&%{&1 | selected: &1.id == selection_id})

    {:noreply, assign(socket, templates: templates)}
  end

  def handle_event(event, _params, socket) do
    Logger.debug("[PrintClientWeb.TemplatesLive]: Unhandled event received: #{event}")
    {:noreply, socket}
  end

  defp assign_templates(socket) do
    templates =
      Label.Template.load_templates()
      |> Enum.map(&Map.put(&1, :selected, false))

    locations = [
      %{path: Label.Template.internal_templates_path()},
      %{path: "./Templates"},
      %{path: "~/Templates"},
      %{path: "~/Documents/Templates"}
    ]

    socket
    |> assign(templates: templates)
    |> assign(:locations, locations)
  end
end
