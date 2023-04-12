defmodule PrintClientWeb.PrintClientLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  require Logger

  @impl true
  def mount(_args, _session, socket) do
    Phoenix.PubSub.subscribe(PrintClient.PubSub, "menu_action")

    printers = Settings.all_printers()

    current = Enum.find(printers, List.first(printers), fn p -> p.selected == 1 end)
    Logger.debug("Current printer: #{inspect current}")

    if current == nil do
      {:ok, redirect(socket, to: "/settings")}
    else
      {:ok, assign(socket, %{printers: printers, current_printer: current})}
    end
  end

  @impl true
  def handle_event("select-printer", %{"printer" => printer}, socket) do
    with {id_num, _} <- Integer.parse(printer) do
      new_printer = Enum.find(Settings.all_printers(), fn p -> p.id == id_num end)
      Logger.debug("Selecting printer #{inspect new_printer}")
      {:noreply, assign(socket, current_printer: new_printer)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("print-text", %{"copies" => copies, "text" => text}, socket) do
    Logger.debug("Printing to #{inspect socket.assigns.current_printer}")

    GenServer.cast(PrintQueue, {:push, %{
      printer: socket.assigns.current_printer,
      text: text,
      copies: copies
    }})

    Desktop.Window.show_notification(PrintClientWindow, "Printing text label: #{text}", timeout: 1000)

    {:noreply, socket}
  end

  @impl true
  def handle_event("print-asset", %{"copies" => copies, "asset" => asset, "serial" => serial}, socket) do
    if not Regex.match?(~r/^[0-9]+$/, asset) do
      Desktop.Window.show_notification(PrintClientWindow, "Asset number \"#{asset}\" may be malformed", timeout: 5000)
    end

    if not Regex.match?(~r/^[A-z0-9]+$/, serial) do
      Desktop.Window.show_notification(PrintClientWindow, "Serial number \"#{serial}\" may be malformed", timeout: 5000)
    end

    GenServer.cast(PrintQueue, {:push, %{
      printer: socket.assigns.current_printer,
      asset: asset,
      serial: serial,
      copies: copies,
    }})

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
