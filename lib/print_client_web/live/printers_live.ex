defmodule PrintClientWeb.PrintersLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.live_component id="printer-settings" module={PrintClientWeb.Settings.PrinterComponent} />
    </Layouts.app>
    """
  end

  def assign_printer(socket, :edit, printer_id \\ nil) do
    printer =
      case printer_id do
        nil -> %Settings.Printer{}
      end

    socket
    |> assign(printer: printer)
  end
end
