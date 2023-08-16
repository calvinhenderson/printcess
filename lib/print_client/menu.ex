defmodule PrintClient.Menu do
  @moduledoc """
  Action Menu for the taskbar icon.
  """
  import PrintClientWeb.Gettext

  use Desktop.Menu
  alias Desktop.Menu

  alias PrintClientWeb.{Router, Endpoint}

  def mount(menu) do
    # This impure function sets the icon externally through wxWidgets
    Menu.set_icon(menu, {:file, "icon32x32.png"})

    {:ok, menu}
  end

  def handle_info(_, menu) do
    {:noreply, menu}
  end

  def handle_event("quit", menu),
    do: Desktop.Window.quit() |> then(fn _ -> {:noreply, menu} end)

  def handle_event("toggle", menu) do
    if Desktop.Window.is_hidden?(PrintClientWindow),
      do: show_window(),
      else: hide_window()

    {:noreply, menu}
  end

  def handle_event("show-queue", menu) do
    PrintClient.JobQueue.init()
    {:noreply, menu}
  end

  def handle_event("asset-spam", menu) do
    url = Router.Helpers.asset_print_url(Endpoint, :index)
    Desktop.Window.show(PrintClientWindow, url)
    {:noreply, menu}
  end

  def handle_event("settings", menu) do
    settings_url = Router.Helpers.live_url(Endpoint, PrintClientWeb.SettingsLive)

    Desktop.Window.show(PrintClientWindow, settings_url)
    |> then(fn _ -> {:noreply, menu} end)

    {:noreply, menu}
  end

  def render(assigns) do
    ~H"""
    <menu>
      <%= if Enum.member?([:dev,:test], Application.get_env(:print_client, :env)) do %>
        <item><%= gettext "Dev build" %></item>
        <hr/>
      <% end %>
      <item onclick="toggle"><%= gettext "Toggle Window" %></item>
      <item onclick="show-queue"><%= gettext "Show Queue" %></item>
      <hr/>
      <item onclick="asset-spam"><%= gettext "Assets Only" %></item>
      <hr/>
      <item onclick="settings"><%= gettext "Settings" %></item>
      <hr/>
      <item onclick="quit"><%= gettext "Quit" %></item>
    </menu>
    """
  end

  defp hide_window, do: Desktop.Window.hide(PrintClientWindow)

  defp show_window do
    live_url = Router.Helpers.live_url(Endpoint, PrintClientWeb.PrintClientLive)
    Desktop.Window.show(PrintClientWindow, live_url)
  end
end
