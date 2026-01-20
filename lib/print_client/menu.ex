defmodule PrintClient.Menu do
  @moduledoc """
  Action Menu for the taskbar icon.
  """
  import PrintClientWeb.Gettext
  use PrintClientWeb, :verified_routes

  use Desktop.Menu
  alias Desktop.Menu

  @impl true
  def mount(menu) do
    # This impure function sets the icon externally through wxWidgets
    Menu.set_icon(menu, {:file, "icon32x32.png"})

    {:ok, menu}
  end

  @impl true
  def handle_info(_event, menu) do
    {:noreply, menu}
  end

  @impl true
  def handle_event("quit", menu),
    do: Desktop.Window.quit() |> then(fn _ -> {:noreply, menu} end)

  @impl true
  def handle_event("show", menu), do: show_url(menu, ~p"/")

  @impl true
  def handle_event("settings", menu), do: show_url(menu, ~p"/settings")

  @impl true
  def render(assigns) do
    ~H"""
    <menu>
      <%= if show_dev_tools() do %>
        <item>{gettext("Dev build")}</item>
        <hr />
      <% end %>
      <item onclick="show">{gettext("Show")}</item>
      <item onclick="settings">{gettext("Settings")}</item>
      <item onclick="quit">{gettext("Quit")}</item>
    </menu>
    """
  end

  defp show_url(menu, url) do
    PrintClient.Window.Print.show()
    PrintClient.Window.Print.load_url(url)
    {:noreply, menu}
  end

  defp show_dev_tools,
    do:
      Application.get_env(:print_client, PrintClient.Window, %{show_dev_tools: true})[
        :show_dev_tools
      ]
end
