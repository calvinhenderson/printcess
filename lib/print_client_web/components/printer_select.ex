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

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="join join-horizontal">
      <.dropdown :let={printer} options={@printers} label="Printer" class="join-item">
        <div phx-click="select" phx-target={@myself} phx-value-id={printer.printer_id}>
          {printer.name}
        </div>
      </.dropdown>
      <.button phx-target={@myself} phx-click="refresh" class="join-item">
        <.icon name="hero-arrow-path" />
      </.button>
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
