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
      <.header>
        Printing Views
        <:actions>
          <.button variant="primary" navigate={~p"/views/new"}>
            <.icon name="hero-plus" /> New View
          </.button>
        </:actions>
      </.header>

      <div
        id="views"
        phx-update="stream"
        class="list bg-base-100 rounded-box shadow-md cursor-pointer"
      >
        <div
          :for={{id, view} <- @streams.views}
          id={id}
          phx-click={JS.navigate(~p"/views/#{view.id}")}
          class="list-row"
        >
          <PrintComponents.label_template
            class="cursor-pointer"
            template={Enum.find(@templates, &(&1.id == view.template))}
          />
          <div class="list-col-grow">
            <div class="flex flex-wrap justify-start items-start gap-2 h-full">
              <.live_component
                :for={p <- view.printers |> Enum.take(2)}
                module={PrinterCardLive}
                id={"#{id}-printer-#{p.id}"}
                class="min-w-60 max-w-60"
                printer={p}
                nolink
                compact
              />
            </div>
          </div>
          <span :if={length(view.printers) > 2} class="m-2 badge badge-soft badge-sm badge-outline">
            + {length(view.printers) - 2} more
          </span>
          <div class="flex flex-col gap-4 justify-start w-20">
            <.link class="btn btn-accent w-full" navigate={~p"/views/#{view}/edit"}>Edit</.link>
            <.link
              class="btn btn-error w-full"
              phx-click={JS.push("delete", value: %{id: view.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </div>
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
     |> stream(:views, Views.all_views())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    view = Views.get_view!(id)
    {:ok, _} = Views.delete_view(view)

    {:noreply, stream_delete(socket, :views, view)}
  end
end
