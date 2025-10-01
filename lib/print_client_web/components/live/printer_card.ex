defmodule PrintClientWeb.PrinterCardLive do
  @moduledoc """
  Renders a live card for an individual printer.
  """

  use PrintClientWeb, :live_component

  alias PrintClient.Printer

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{source: :pubsub, message: {_printer_id, :status, status}}, socket) do
    {:ok,
     socket
     |> assign(:online, status)}
  end

  @impl true
  def update(params, socket) do
    printer = get_in(params, [:printer])

    if not is_nil(printer) do
      {:ok, _pid, printer} =
        Printer.Supervisor.start_printer(printer)

      PrintClient.PubSub.subscribe(socket, PrintClient.PubSub, "printers:#{printer.printer_id}")
    end

    assigns =
      socket.assigns
      |> Map.merge(params)
      |> Map.merge(%{
        online: nil,
        printer: printer
      })

    {:ok, %{socket | assigns: assigns}}
  end

  attr :id, :any, required: true
  attr :class, :any, default: ""
  attr :compact, :boolean, default: false
  attr :nolink, :boolean, default: false
  slot :actions, required: false

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class={[
        @class,
        "card w-full bg-base-100 card-sm shadow-sm",
        @compact && "h-14",
        @compact || "h-auto",
        @nolink || "cursor-pointer"
      ]}
      phx-click={if @nolink, do: false, else: JS.navigate(~p"/printers/#{@printer.id}")}
    >
      <div class="card-body">
        <div class="card-title">
          <div class="inline-grid *:[grid-area:1/1]">
            <div class={[
              "status",
              connected?(@socket) && "animate-ping",
              @online && "status-success",
              is_nil(@online) or @online || "status-error",
              is_nil(@online) && "status-ghost"
            ]}>
            </div>
            <div class={[
              "status",
              @online && "status-success",
              is_nil(@online) or @online || "status-error",
              is_nil(@online) && "status-ghost"
            ]}>
            </div>
            <span class="sr-only">Printer is {@online && gettext("online")}
              {@online || gettext("offline")}</span>
          </div>
          <h2 class="truncate">{@printer.name}</h2>
          <span :if={@printer.type == :network} class="ml-auto badge badge-soft badge-primary">
            {gettext("Network")}
          </span>
          <span :if={@printer.type == :serial} class="ml-auto badge badge-soft badge-secondary">
            {gettext("Serial")}
          </span>
          <span :if={@printer.type == :usb} class="ml-auto badge badge-soft badge-accent">
            {gettext("USB")}
          </span>
        </div>
        <div :if={not @compact}>
          <div :if={@printer.type == :network}>
            <p>{@printer.hostname}:{@printer.port}</p>
          </div>
          <div :if={@printer.type == :serial}>
            <p>Port: {@printer.serial_port}</p>
          </div>
          <div :if={@printer.type == :usb}>
            <p>Device: {@printer.vendor_id}:{@printer.product_id}</p>
          </div>
        </div>
        <div :if={@actions} class="card-actions ml-auto">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  def handle_event({_printer_id, :status, status}, socket),
    do: {:noreply, socket |> assign(:online, status)}

  def handle_event(_msg, socket), do: {:noreply, socket}
end
