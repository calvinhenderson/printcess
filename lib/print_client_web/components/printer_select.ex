defmodule PrintClientWeb.PrinterSelectComponent do
  alias PrintClient.Printer
  use PrintClientWeb, :live_component

  alias PrintClient.Printer.Discovery

  require Logger

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(value: nil)
      |> assign_printers()
      |> notify_selected()

    {:ok, socket}
  end

  @impl true
  def handle_event("select", %{"select" => printer_id}, socket) do
    {:noreply, socket |> notify_selected(printer_id)}
  end

  def handle_event("select", _params, socket), do: {:noreply, socket}

  def handle_event("refresh", _params, socket) do
    Logger.debug("PrinterSelectComponent: refreshing printers")

    {:noreply, socket |> assign_printers()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-4">
      <form id={@id <> "-form"} phx-change="select" phx-target={@myself}>
        <select
          id={@id <> "-select"}
          name="select"
          class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm sm:w-min"
          value={@value}
          list={@id <> "-list"}
        >
          <option value="" selected={true}>Select a printer</option>
          <option :for={{name, value} <- @printer_options} value={value} selected={false}>
            {name}
          </option>
        </select>
      </form>
      <.button phx-target={@myself} phx-click="refresh">
        <.icon name="hero-arrow-path" />
      </.button>
    </div>
    """
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
