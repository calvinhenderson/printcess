defmodule PrintClientWeb.SettingsLive do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.Settings

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.live_component :if={@tab == :printers} id="printers" module={Settings.PrinterComponent} />
      <.live_component
        :if={@tab == :preferences}
        id="preferences"
        module={Settings.UserPreferencesComponent}
      />
      <.live_component :if={@tab == :api} id="api" module={Settings.ApiComponent} />
    </Layouts.app>
    """
  end

  defp apply_action(socket, action, _params) do
    case action do
      :printers ->
        assign_tab(socket, :printers, "Printer Settings")

      :preferences ->
        assign_tab(socket, :preferences, "User Preferences")

      :api ->
        assign_tab(socket, :api, "API Settings")
    end
  end

  defp assign_tab(socket, tab, page_title \\ nil) do
    socket
    |> assign(:page_title, page_title)
    |> assign(:tab, tab)
  end
end
