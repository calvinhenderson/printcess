defmodule PrintClientWeb.PrintersLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        id="printer-settings"
        module={PrintClientWeb.Settings.PrinterComponent}
        printer={@printer}
      />
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
