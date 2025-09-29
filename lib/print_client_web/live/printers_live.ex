defmodule PrintClientWeb.PrintersLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign_printer(get_in(params, ["id"]))}
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

  defp assign_printer(socket, printer_id)

  defp assign_printer(socket, nil),
    do: assign(socket, printer: %Settings.Printer{})

  defp assign_printer(socket, printer_id),
    do: assign(socket, printer: Settings.get_printer!(printer_id))
end
