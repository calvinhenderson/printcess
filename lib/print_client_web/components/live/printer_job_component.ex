defmodule PrintClientWeb.PrinterJobComponent do
  @moduledoc """

  The when a user clicks submit, the print form will send a message to the
  parent liveview with the print job id(s). The parent liveview will render
  this component with the list of print jobs (a stream) and each job will
  be updated with the status of each printer. each printer will contain a
  refresh button that will resend the job to the printer. the job will also
  have an edit button that will allow you to edit the params of the last job
  (to correct spellings or whatever is needed.)

  """

  use PrintClientWeb, :live_component

  alias PrintClient.Printer

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{source: :pubsub, message: {printer_id, {:job, job_id}, status}}, socket) do
    {:ok,
     socket
     |> assign(id: "#{printer_id}-#{job_id}")
     |> assign_job_status(status)}
  end

  @impl true
  def update(assigns, socket) do
    socket = %{socket | assigns: Map.merge(socket.assigns, assigns)}

    {:ok,
     socket
     |> assign_job()
     |> assign_job_status(:fetch)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="collapse collapse-arrow bg-base-100 border border-base-200 shadow-sm rounded-box mb-2 group"
    >
      <input type="checkbox" />

      <div class="collapse-title flex items-center justify-between gap-4 py-4 pr-12">
        <div class="flex items-center gap-3">
          <div class={[
            "w-8 h-8 rounded-lg flex items-center justify-center",
            @status == :complete && "bg-success/10 text-success",
            @status == :failed && "bg-error/10 text-error",
            @status == :processing && "bg-primary/10 text-primary",
            @status == :cancelled && "bg-base-200 text-base-content/50"
          ]}>
            <.icon name="hero-printer-solid" class="w-5 h-5" />
          </div>

          <div class="flex flex-col">
            <span class="font-bold text-base-content">{@printer.name}</span>
            <span class="text-xs text-base-content/50 font-mono">
              Job: #{to_string(@id)}
            </span>
            <span class="text-xs text-base-content/50 font-mono">
              Template:
              <%= case @job.template do %>
                <% %{name: name} -> %>
                  {name}
                <% {path, name} -> %>
                  {name}
              <% end %>
            </span>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <div :if={@status == :processing} class="hidden sm:flex flex-col w-32 gap-1">
            <progress class="progress progress-primary w-full" value="50" max="100"></progress>
            <span class="text-[10px] text-right opacity-60">Printing...</span>
          </div>

          <div class={[
            "badge gap-2 font-medium",
            @status == :complete && "badge-success badge-soft",
            @status == :failed && "badge-error badge-soft",
            @status == :processing && "badge-primary badge-soft",
            @status == :cancelled && "badge-ghost"
          ]}>
            <span :if={@status == :processing} class="loading loading-spinner loading-xs"></span>
            {@status |> to_string() |> String.capitalize()}
          </div>
        </div>
      </div>

      <div class="collapse-content text-sm border-t border-base-100">
        <div class="pt-4 flex flex-col gap-6">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-y-4 gap-x-8">
            <%= for {k, v} <- @job.params do %>
              <div class="flex flex-col gap-0.5">
                <span class="text-xs uppercase tracking-wider font-semibold text-base-content/40">
                  {k}
                </span>
                <span class="font-mono text-base-content/90 truncate select-all bg-base-200/50 px-2 py-1 rounded">
                  {v}
                </span>
              </div>
            <% end %>
          </div>

          <div class="flex justify-end gap-2 pt-2">
            <.button
              phx-target={@myself}
              phx-click="cancel"
              disabled={@complete}
              class="btn btn-sm btn-ghost text-error hover:bg-error/10"
            >
              Cancel
            </.button>

            <.button
              phx-target={@myself}
              phx-click="resend"
              disabled={not @complete}
              class="btn btn-sm btn-outline border-base-300 hover:border-base-content hover:bg-base-content hover:text-base-100"
            >
              <.icon name="hero-arrow-path" class="w-4 h-4" /> Resend Job
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "cancel",
        _params,
        %{assigns: %{job: %{id: job_id}, printer: printer}} = socket
      ) do
    Printer.cancel_job(printer.printer_id, job_id)

    {:noreply,
     socket
     |> assign(status: :cancelled)
     |> assign(complete: false)}
  end

  @impl true
  def handle_event(
        "resend",
        _params,
        %{assigns: %{job: %{template: template, params: params}, printer: printer}} = socket
      ) do
    Printer.add_job(printer.printer_id, template, params)
    {:noreply, socket}
  end

  defp assign_job(%{assigns: %{job: job, printer: printer}} = socket) do
    topic = Printer.topic(printer, job.id)
    PrintClient.PubSub.subscribe(socket, PrintClient.PubSub, topic)

    socket
    |> assign(topic: topic)
  end

  defp assign_job_status(%{assigns: %{job: job, printer: printer}} = socket, :fetch) do
    status =
      case Printer.get_job(printer.printer_id, job.id) do
        {:ok, %{status: status}} ->
          status

        error ->
          :failed
      end

    socket
    |> assign(status: status)
    |> assign(complete: job_complete?(status))
  end

  defp assign_job_status(socket, status) do
    socket
    |> assign(status: status)
    |> assign(complete: job_complete?(status))
  end

  defp job_complete?(status), do: status in [:complete, :failed, :cancelled]
end
