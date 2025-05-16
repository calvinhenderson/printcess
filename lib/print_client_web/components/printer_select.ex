defmodule PrintClientWeb.PrinterSelectComponent do
  alias PrintClient.Printer
  use PrintClientWeb, :live_component

  alias PrintClient.Printer.Discovery

  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(selected: nil)
     |> assign_printers()
     |> notify_selected()}
  end

  @impl true
  def handle_event("select", %{"select" => printer_id}, socket) do
    Logger.info("PrinterSelectComponent: selected #{inspect(printer_id)}")

    socket = socket |> assign_selected(printer_id)

    send(self(), {:select_printer, socket.assigns.selected})

    {:noreply,
     socket
     |> assign_selected(printer_id)}
  end

  def handle_event("select", _, socket) do
    Logger.info("PrinterSelectComponent: deselected")

    socket = socket |> assign_selected(nil)

    send(self(), {:select_printer, nil})

    {:noreply,
     socket
     |> assign_selected(nil)}
  end

  def handle_event("refresh", _params, socket) do
    Logger.info("PrinterSelectComponent: refreshing printers")

    send(self(), {:select_printer, nil})

    {:noreply, socket |> assign_printers() |> assign(selected: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>Printer Select Form</.header>
      <div class="flex flex-row gap-4">
        <form id={@id <> "-form"} phx-change="select" phx-target={@myself}>
          <.input
            id={@id <> "-select"}
            name="select"
            type="select"
            options={@printer_options}
            disabled={@selected != nil}
          />
        </form>
        <.button phx-target={@myself} phx-click="refresh">
          <.icon name={if @selected == nil, do: "hero-arrow-path", else: "hero-trash"} />
        </.button>
      </div>
    </div>
    """
  end

  defp assign_printers(socket) do
    printers = Discovery.discover_all_printers()

    printer_options =
      printers
      |> Enum.reduce([], fn printer, acc ->
        [{printer.name, printer.printer_id} | acc]
      end)
      |> Enum.reverse()

    socket
    |> assign(printers: printers)
    |> assign(printer_options: printer_options)
  end

  defp assign_selected(socket, printer_id),
    do:
      assign(
        socket,
        :selected,
        Enum.find(socket.assigns[:printers], &(&1.printer_id == printer_id))
      )

  defp notify_selected(%{assigns: %{selected: %{printer_id: printer_id}}} = socket) do
    # We need to notify Printer.Supervisor to start the queue
    Printer.Supervisor.start_printer(printer_id)

    socket
  end

  defp notify_selected(socket), do: socket
end
