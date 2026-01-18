defmodule PrintClientWeb.ViewLive.Index do
  use PrintClientWeb, :live_view

  alias PrintClient.Views
  alias PrintClient.Label.Template
  alias PrintClientWeb.PrintComponents
  alias PrintClientWeb.PrinterCardLive

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
        <div>
          <h1 class="text-2xl font-bold text-base-content">Printing Views</h1>
          <p class="text-base-content/60">Manage your template-to-printer configurations</p>
        </div>
        <.link navigate={~p"/views/new"} class="btn btn-primary">
          <.icon name="hero-plus" class="w-5 h-5" />
          <span>New View</span>
        </.link>
      </div>

      <div id="views" phx-update="stream" class="flex flex-col gap-4">
        <a :for={{id, view} <- @streams.views} id={id} href={~p"/views/#{view.id}"}>
          <div class="w-full card card-side bg-base-100 shadow-sm border border-base-200 transition-all hover:shadow-md group">
            <figure class="w-48 bg-base-200/50 p-4 border-r border-base-200 flex items-center justify-center">
              <div class="w-full shadow-sm bg-white rounded overflow-hidden">
                <PrintComponents.label_template
                  class="w-full h-auto pointer-events-none select-none"
                  template={Enum.find(@templates, &(&1.id == view.template))}
                />
              </div>
            </figure>

            <div class="card-body p-6 flex-row gap-6 items-center">
              <div class="flex-1 min-w-0 flex flex-col gap-3">
                <div>
                  <h3 class="font-bold text-lg leading-tight">
                    {Enum.find(@templates, &(&1.id == view.template)).name || "Untitled Template"}
                  </h3>
                  <span class="text-xs font-mono text-base-content/50 uppercase tracking-wider">
                    View ID: {String.slice(to_string(view.id), 0..7)}
                  </span>
                </div>

                <div class="flex flex-col gap-1.5">
                  <span class="text-xs font-semibold text-base-content/40 flex items-center gap-1">
                    <.icon name="hero-printer" class="w-3 h-3" /> DESTINATIONS
                  </span>
                  <div class="flex flex-wrap items-center gap-2">
                    <.live_component
                      :for={p <- view.printers |> Enum.take(3)}
                      module={PrinterCardLive}
                      id={"#{id}-printer-#{p.id}"}
                      class="scale-90 origin-left"
                      printer={p}
                      nolink
                      compact
                    />
                    <span :if={length(view.printers) > 3} class="badge badge-ghost text-xs">
                      + {length(view.printers) - 3} others
                    </span>
                    <span :if={Enum.empty?(view.printers)} class="text-sm text-base-content/50 italic">
                      No printers assigned
                    </span>
                  </div>
                </div>
              </div>

              <div class="flex flex-col ml-auto justify-self-end items-center gap-2 border-l border-base-200 pl-4">
                <div class="tooltip" data-tip="Edit View">
                  <.link
                    navigate={~p"/views/#{view.id}/edit"}
                    class="btn btn-square btn-ghost hover:bg-primary hover:text-primary-content"
                  >
                    <.icon name="hero-pencil-square" class="w-5 h-5" />
                  </.link>
                </div>

                <div class="tooltip" data-tip="Delete View">
                  <.link
                    phx-click={JS.push("delete", value: %{id: view.id}) |> hide("##{id}")}
                    data-confirm="Are you sure you want to delete this view?"
                    class="btn btn-square btn-ghost hover:bg-error hover:text-error-content"
                  >
                    <.icon name="hero-trash" class="w-5 h-5" />
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </a>

        <div
          id="views-empty-state"
          class="hidden only:block text-center py-20 bg-base-100 rounded-box border border-dashed border-base-300"
        >
          <div class="opacity-50 mb-4">
            <.icon name="hero-rectangle-stack" class="w-12 h-12 mx-auto" />
          </div>
          <h3 class="text-lg font-bold">No views created yet</h3>
          <p class="text-base-content/60 mb-4">
            Combine a template with printers to create your first view.
          </p>
          <.link navigate={~p"/views/new"} class="btn btn-primary btn-sm">Create View</.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Views")
     |> assign(:templates, Template.load_templates())
     |> assign_views()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    view = Views.get_view!(id)
    {:ok, _} = Views.delete_view(view)

    {:noreply, stream_delete(socket, :views, view)}
  end

  defp assign_views(socket) do
    if connected?(socket) do
      stream(socket, :views, Views.all_views())
    else
      stream(socket, :views, Views.all_views())
    end
  end
end
