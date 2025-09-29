defmodule PrintClientWeb.ViewLive.Show do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.PrinterJobComponent
  alias PrintClient.Views
  alias PrintClient.Printer
  alias PrintClient.Label.Template
  alias PrintClientWeb.PrintForm
  alias PrintClientWeb.PrinterCardLive

  import PrintClientWeb.PrintComponents

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        <.button navigate={~p"/views"}>
          <.icon name="hero-arrow-left" /> Views
        </.button>
        <:actions>
          <.button navigate={~p"/views/#{@view}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit
          </.button>
        </:actions>
      </.header>

      <div class="space-y-8 max-w-lg mx-auto">
        <div>
          <.header>Template</.header>
          <div class="space-y-8">
            <.label_template params={@label_params} template={@template} />
            <.live_component
              id="print-form"
              module={PrintForm}
              template={@template}
              printers={@printers}
              disabled={@printers == []}
            />
          </div>
        </div>

        <div>
          <.header class="mt-8">Printers</.header>

          <.empty_placeholder
            :if={@printers == []}
            label={gettext("add a printer")}
            navigate={~p"/views/#{@view.id}/edit?return_to=show"}
          />

          <div
            :if={@printers != []}
            class="grid grid-flow-rows grid-cols-1 md:grid-cols-2 w-full gap-4 lg:gap-8 justify-between"
          >
            <.live_component
              :for={p <- @printers}
              module={PrinterCardLive}
              id={@id <> "-#{p.id}-card"}
              printer={p}
              compact
            />
          </div>
        </div>

        <div>
          <.header class="mt-8">Job History</.header>

          <div
            id={"#{@id}-job-list"}
            class="bg-base-100 rounded-box shadow-md"
            phx-update="stream"
          >
            <.live_component
              :for={{id, job} <- @streams.jobs}
              module={PrinterJobComponent}
              id={id}
              job={job}
            />
            <p id={"#{@id}-job-list-end"} class="p-4">End of job history</p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    view = Views.get_view!(id)

    {:ok,
     socket
     |> assign(:id, "view-" <> id)
     |> assign(:page_title, "View #{view.id}")
     |> assign(:view, view)
     |> assign_template()
     |> assign_printers()
     |> stream(:jobs, [], at: 0)}
  end

  @impl true
  def handle_info({:changed, params}, socket),
    do: {:noreply, socket |> assign(:label_params, params)}

  @impl true
  def handle_info({printer_id, :job_added, job}, socket) do
    {:ok, printer_status} = Printer.status(printer_id)

    {:noreply, 
      socket
      |> stream_insert(:jobs,
        Map.put(job, :printer, printer_status),
        dom_id: "#{printer_id}-#{job.id}"
      )}
  end

  @impl true
  def handle_info(_msg, socket), do: {:noreply, socket}

  defp assign_template(%{assigns: %{view: view}} = socket) do
    template =
      Template.load_templates()
      |> Enum.find(&(&1.id == view.template))

    socket
    |> assign(:template, template)
    |> assign(:label_params, placeholder_for_template_fields(template.form_fields))
  end

  defp assign_printers(%{assigns: %{view: view}} = socket) do
    for printer <- view.printers do
      printer_topic = Printer.topic(printer)
      PrintClient.PubSub.subscribe(socket, PrintClient.PubSub, printer_topic)
    end
    socket |> assign(:printers, view.printers)
  end
end
