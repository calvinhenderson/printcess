defmodule PrintClientWeb.ViewLive.Show do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.PrinterJobComponent
  alias PrintClient.Views
  alias PrintClient.Printer
  alias PrintClient.Printer.PrintJob
  alias PrintClient.Label.Template
  alias PrintClientWeb.PrintForm
  alias PrintClientWeb.PrinterCardLive

  import PrintClientWeb.PrintComponents

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-[1600px] mx-auto pb-12">
        <div class="flex items-center justify-between mb-8 pb-4 border-b border-base-200">
          <div class="flex items-center gap-4">
            <.link
              navigate={~p"/views"}
              class="btn btn-circle btn-ghost btn-sm tooltip tooltip-right"
              data-tip="Back to Views"
            >
              <.icon name="hero-arrow-left" class="w-5 h-5" />
            </.link>
            <div>
              <h1 class="text-2xl font-bold text-base-content leading-tight">
                {if @template, do: @template.name, else: "Print View"}
              </h1>
              <div class="flex items-center gap-2 text-xs font-mono text-base-content/50">
                <span>ID: {@view.id}</span>
                <span class="w-1 h-1 rounded-full bg-base-300"></span>
                <span class={if @printers == [], do: "text-error", else: "text-success"}>
                  {length(@printers)} Printer{if length(@printers) != 1, do: "s"} Selected
                </span>
              </div>
            </div>
          </div>

          <.link
            navigate={~p"/views/#{@view}/edit?return_to=show"}
            class="btn btn-primary btn-sm btn-outline gap-2"
          >
            <.icon name="hero-cog-6-tooth" class="w-4 h-4" />
            <span class="hidden sm:inline">Configure View</span>
          </.link>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          <div class="lg:col-span-7 flex flex-col gap-6">
            <div class="card bg-base-100 shadow-sm border border-base-200 overflow-hidden">
              <div class="card-body p-0">
                <div class="bg-base-200/40 p-10 flex items-center justify-center min-h-[320px] relative">
                  <div class="shadow-xl rounded bg-white transition-transform duration-300 hover:scale-[1.02]">
                    <.label_template params={@label_params} template={@template} />
                  </div>
                  <div class="absolute bottom-4 right-4 text-[10px] uppercase tracking-widest text-base-content/30 font-bold">
                    Live Preview
                  </div>
                </div>
              </div>
            </div>

            <div class="card bg-base-100 shadow-sm border border-base-200">
              <div class="card-body">
                <div class="flex items-center gap-2 mb-6 pb-4 border-b border-base-100">
                  <div class="p-2 bg-primary/10 text-primary rounded-lg">
                    <.icon name="hero-adjustments-horizontal" class="w-5 h-5" />
                  </div>
                  <div>
                    <h2 class="card-title text-base">Print Parameters</h2>
                    <p class="text-xs text-base-content/50">Fill in dynamic fields from template</p>
                  </div>
                </div>

                <.live_component
                  id="print-form"
                  module={PrintForm}
                  template={@template}
                  printers={@printers}
                  disabled={@printers == []}
                />
              </div>
            </div>
          </div>

          <div class="lg:col-span-5 flex flex-col gap-6 lg:sticky lg:top-6">
            <div class="card bg-base-100 shadow-sm border border-base-200">
              <div class="card-body p-5">
                <h3 class="text-xs font-bold uppercase text-base-content/40 tracking-wider mb-3">
                  Destinations
                </h3>

                <.empty_placeholder
                  :if={@printers == []}
                  label="No printers configured"
                  navigate={~p"/views/#{@view.id}/edit?return_to=show"}
                />

                <div :if={@printers != []} class="flex flex-col gap-3">
                  <div
                    :for={p <- @printers}
                    class="rounded-xl border border-base-200 p-1 hover:border-primary/30 transition-colors bg-base-50/50"
                  >
                    <.live_component
                      module={PrinterCardLive}
                      id={@id <> "-#{p.id}-card"}
                      printer={p}
                      compact
                      nolink
                    />
                  </div>
                </div>
              </div>
            </div>

            <div class="card bg-base-100 shadow-sm border border-base-200 flex flex-col max-h-[calc(100vh-300px)]">
              <div class="p-5 border-b border-base-200 bg-base-100 z-10 rounded-t-xl flex justify-end gap-4 items-center">
                <h3 class="text-xs font-bold uppercase text-base-content/40 tracking-wider mr-auto">
                  Activity Log
                </h3>
                <span class="badge badge-sm badge-ghost">
                  {length(@streams.jobs.inserts)} Events
                </span>
                <.link navigate={~p"/jobs"} class="btn btn-sm btn-primary">All Jobs</.link>
              </div>

              <div
                id={"#{@id}-job-list"}
                phx-update="stream"
                class="overflow-y-auto p-3 flex flex-col gap-2 flex-1 min-h-[200px]"
              >
                <.live_component
                  :for={{id, %{job: job, printer: printer}} <- @streams.jobs}
                  module={PrinterJobComponent}
                  id={id}
                  job={job}
                  printer={printer}
                />

                <div id={"#{@id}-job-list-end"} class="text-center py-8">
                  <p
                    :if={Enum.empty?(@streams.jobs.inserts)}
                    class="text-sm text-base-content/40 italic"
                  >
                    Ready to print. Jobs will appear here.
                  </p>
                  <div
                    :if={!Enum.empty?(@streams.jobs.inserts)}
                    class="divider text-xs text-base-content/30"
                  >
                    End of History
                  </div>
                </div>
              </div>
            </div>
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
    template_id = socket.assigns.template.id

    with %{template: %{id: ^template_id}} <- job,
         {:ok, printer_status} <- Printer.status(printer_id) do
      socket
      |> stream_insert(
        :jobs,
        %{
          id: "#{printer_id}:#{job.id}",
          job: job,
          printer: printer_status
        },
        at: 0
      )
    else
      %PrintJob{} ->
        socket

      error ->
        Logger.debug("[ViewLive.Show]: Error adding job to queue #{inspect(error)}")
        socket
    end
    |> then(&{:noreply, &1})
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
