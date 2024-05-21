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

  def handle_event("show", menu) do
    PrintClient.Window.Print.show()
    {:noreply, menu}
  end

  def handle_event("asset-spam", menu) do
    PrintClient.Window.BulkAssetPrint.show()
    {:noreply, menu}
  end

  def handle_event("settings", menu) do
    PrintClient.Window.Settings.show()
    {:noreply, menu}
  end

  def render(assigns) do
    ~H"""
    <menu>
      <%= if Enum.member?([:dev,:test], Application.get_env(:print_client, :env)) do %>
        <item><%= gettext("Dev build") %></item>
        <hr />
      <% end %>
      <item onclick="show"><%= gettext("Show") %></item>
      <item onclick="asset-spam"><%= gettext("Bulk") %></item>
      <item onclick="settings"><%= gettext("Settings") %></item>
      <item onclick="quit"><%= gettext("Quit") %></item>
    </menu>
    """
  end
end
