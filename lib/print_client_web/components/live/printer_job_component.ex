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
    <div id={@id} class="collapse collapse-arrow rounded-none bg-base-100 border-base-300 border">
      <input type="checkbox" />
      <div class="collapse-title font-semibold flex justify-between items-center">
        <span class="inline-block">{@printer.name}</span>
        <progress
          class={[
            "progress w-56",
            @status == :complete && "progress-success",
            @status == :failed && "progress-error",
            @status == :cancelled && "progress-warning"
          ]}
          value={(@status == :processing && "50") || (@complete && "100")}
          max={(@status == :processing && "50") || (@complete && "100")}
        >
        </progress>

        <span>{@status |> to_string() |> String.capitalize()}</span>
      </div>

      <div class="collapse-content space-y-4 text-right">
        <.button
          phx-target={@myself}
          phx-click="resend"
          phx-disable-with="Resending.."
          disabled={not @complete}
        >
          <.icon name="hero-arrow-path" /> Resend
        </.button>
        <.button
          phx-target={@myself}
          phx-click="cancel"
          phx-disable-with="Cancelling.."
          disabled={@complete}
        >
          <.icon name="hero-x-circle" /> Cancel
        </.button>

        <div class="gap-4 grid grid-cols-[1fr_auto_1fr] grid-flow-rows">
          <%= for {k, v} <- @job.params do %>
            <span class="kbd truncate">{k}</span>
            <.icon name="hero-arrow-long-right self-center" />
            <span class="kbd truncate">{v}</span>
          <% end %>
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
          dbg(error)
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
