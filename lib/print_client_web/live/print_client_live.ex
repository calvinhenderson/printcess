defmodule PrintClientWeb.PrintClientLive do
  use PrintClientWeb, :live_view

  require Logger

  alias PrintClientWeb.{TextForm,AssetForm,PrinterSelect}
  alias PrintClient.Settings

  @impl true
  def mount(_params, _session, socket) do
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
  def render(assigns) do
    ~H"""
      <section class="flex flex-col md:flex-row w-full justify-around p-4 gap-4">
        <.live_component id="printer-select" module={PrinterSelect} current_printer={@current_printer} printers={@printers} />
        <.live_component id="text-form" module={TextForm} printer={@current_printer} />
        <.live_component id="asset-form" module={AssetForm} printer={@current_printer} />
      </section>
    """
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
  def handle_info(:open_text, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:open_asset, socket) do
    {:noreply, socket}
  end
end
