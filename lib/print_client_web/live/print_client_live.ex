defmodule PrintClientWeb.PrintClientLive do
  use PrintClientWeb, :live_view

  require Logger

  @printers [
    %{id: "help-desk-printer", name: "Help Desk — LabelTac 4", host: "10.40.21.189", port: 9100},
    %{id: "tech-office-printer", name: "Tech Office — LabelTac Pro X", host: "10.40.21.154", port: 9100},
  ]

  @impl true
  def mount(_args, _session, socket) do
    Phoenix.PubSub.subscribe(PrintClient.PubSub, "menu_action")

    {:ok, assign(socket, %{printers: @printers, current_printer: List.first(@printers).id})}
  end

  @impl true
  def handle_event("select-printer", %{"printer" => printer}, socket) do
    new_printer = Enum.find(@printers, fn p -> p.id == printer end)
    Logger.debug("Selecting printer #{inspect new_printer}")
    {:noreply, assign(socket, current_printer: new_printer.id)}
  end

  @impl true
  def handle_event("print-text", %{"copies" => copies, "text" => text}, socket) do
    printer = Enum.find(@printers, fn p -> p.id == socket.assigns.current_printer end)

    PrintClient.Print.print(printer, :text, %{text: text}, copies)
    Desktop.Window.show_notification(PrintClientWindow, "Printing text label: #{text}", timeout: 1000)

    {:noreply, socket}
  end

  @impl true
  def handle_event("print-asset", %{"copies" => copies, "asset" => asset, "serial" => serial}, socket) do
    printer = Enum.find(@printers, fn p -> p.id == socket.assigns.current_printer end)

    if not Regex.match?(~r/^[0-9]+$/, asset) do
      Desktop.Window.show_notification(PrintClientWindow, "Asset number \"#{asset}\" may be malformed", timeout: 5000)
    end

    if not Regex.match?(~r/^[A-z0-9]+$/, serial) do
      Desktop.Window.show_notification(PrintClientWindow, "Serial number \"#{serial}\" may be malformed", timeout: 5000)
    end

    PrintClient.Print.print(printer, :asset, %{asset: asset, serial: serial}, copies)
    Desktop.Window.show_notification(PrintClientWindow, "Printing asset label: #{asset},#{serial}", timeout: 1000)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:open_text, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:open_asset, socket) do
    {:noreply, socket}
  end
end
