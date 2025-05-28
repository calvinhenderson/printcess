defmodule PrintClientWeb.PrinterSelectComponent do
  use PrintClientWeb, :live_component

  alias PrintClient.Printer.Discovery
  import PrintClientWeb.PrintComponents, only: [dropdown: 1]

  require Logger

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(value: nil)
      |> assign_printers()
      |> notify_selected()

    Enum.take(socket.assigns.printers, 2)
    |> Enum.each(&send(self(), {:select_printer, &1}))

    Discovery.subscribe()

    {:ok, socket}
  end

  @impl true
  attr :id, :string, required: true

  def render(assigns) do
    ~H"""
    <div id={@id} class="contents">
      <.dropdown results={@printers} class="rounded-l-md">
        <:label class="join join-horizontal">
          <div class="btn btn-soft join-item" role="button" tabindex="0">Printers</div>
          <span phx-target={@myself} phx-click="refresh" class="btn btn-soft join-item">
            <.icon name="hero-arrow-path" />
          </span>
        </:label>
        <:option :let={printer}>
          <div
            role="button"
            phx-click="select"
            phx-target={@myself}
            phx-value-id={printer.printer_id}
            tabindex="0"
          >
            {printer.name}
          </div>
        </:option>
      </.dropdown>
    </div>
    """
  end

  @impl true
  def handle_event("select", %{"id" => printer_id}, socket) do
    {:noreply, socket |> notify_selected(printer_id)}
  end

  def handle_event("select", _params, socket), do: {:noreply, socket}

  def handle_event("refresh", _params, socket) do
    Logger.debug("PrinterSelectComponent: refreshing printers")

    {:noreply, socket |> assign_printers()}
  end

  def handle_info({:added, printer}, socket) do
    socket =
      socket
      |> assign(printers: [printer | socket.assigns.printers])

    {:noreply, socket}
  end

  def handle_info({:removed, printer}, socket) do
    socket =
      socket
      |> assign(
        printers: Enum.reject(socket.assigns.printers, &(&1.printer_id == printer.printer_id))
      )

    {:noreply, socket}
  end

  defp assign_printers(socket) do
    printers = Discovery.discover_all_printers()

    printer_options =
      printers
      |> Enum.reduce([], fn printer, acc ->
        [{"[#{printer.type}] #{printer.name}", printer.printer_id} | acc]
      end)
      |> Enum.reverse()

    socket
    |> assign(printers: printers)
    |> assign(printer_options: printer_options)
  end

  defp notify_selected(socket, printer_id) do
    Logger.debug("PrinterSelectComponent: selected #{inspect(printer_id)}")

    printer =
      socket.assigns.printers
      |> Enum.find(&(&1.printer_id == printer_id))

    if not is_nil(printer), do: send(self(), {:select_printer, printer})

    socket
    |> assign(value: "")
  end

  defp notify_selected(socket), do: socket
end
