defmodule PrintClientWeb.JobsLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Printer
  alias PrintClient.Printer.PrintJob
  alias PrintClientWeb.PrinterJobComponent

  require Logger

  @impl true
  def mount(_, _, socket) do
    printer_ids = Printer.Registry.list()

    jobs =
      printer_ids
      |> Enum.reduce([], fn printer_id, jobs ->
        {:ok, printer_status} = Printer.status(printer_id)

        printer_jobs =
          printer_status.jobs
          |> Enum.map(fn job ->
            %{id: "#{printer_id}:#{job.id}", job: job, printer: printer_status}
          end)

        jobs ++ printer_jobs
      end)

    {:ok,
     socket
     |> stream(:jobs, jobs)
     |> assign(printer_ids: [])
     |> assign_printers(printer_ids)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
        <div>
          <h1 class="text-2xl font-bold text-base-content">Print Jobs</h1>
          <p class="text-base-content/60">View and manage print jobs</p>
        </div>
        <.link navigate={~p"/views"} class="btn btn-primary">
          <.icon name="hero-rectangle-stack" class="w-5 h-5" />
          <span>Views</span>
        </.link>
      </div>

      <div class="card bg-base-100 shadow-sm border border-base-200 flex flex-col max-h-full">
        <div class="p-5 border-b border-base-200 bg-base-100 z-10 rounded-t-xl flex justify-between items-center">
          <h3 class="text-xs font-bold uppercase text-base-content/40 tracking-wider">
            Activity Log
          </h3>
          <span class="badge badge-sm badge-ghost">
            {length(@streams.jobs.inserts)} Events
          </span>
        </div>

        <div
          id="job-list"
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

          <div id="job-list-end" class="text-center py-8">
            <p :if={Enum.empty?(@streams.jobs.inserts)} class="text-sm text-base-content/40 italic">
              Jobs will appear here.
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
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({printer_id, :job_added, job}, socket) do
    with %Printer.PrintJob{} <- job,
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

  def handle_info({:started, printer_id}, socket) do
    {:noreply,
     socket
     |> assign_printers([printer_id])}
  end

  def handle_info({:stopping, printer_id}, socket) do
    printer_topic = Printer.topic(printer_id)
    PrintClient.PubSub.unsubscribe(socket, PrintClient.PubSub, printer_topic)

    {:noreply,
     socket
     |> assign(printer_ids: Enum.reject(socket.assigns.printer_ids, &(&1 == printer_id)))}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp assign_printers(socket, printer_ids) do
    PrintClient.Printer.Supervisor.subscribe()

    printer_ids =
      Enum.reduce(printer_ids, [], fn printer_id, printer_ids ->
        is_alive? =
          Printer.Registry.list()
          |> Enum.member?(printer_id)

        if is_alive? do
          printer_topic = Printer.topic(printer_id)
          PrintClient.PubSub.subscribe(socket, PrintClient.PubSub, printer_topic)
          [printer_id | printer_ids]
        else
          printer_ids
        end
      end)

    socket |> assign(:printers, socket.assigns.printer_ids ++ printer_ids)
  end
end
