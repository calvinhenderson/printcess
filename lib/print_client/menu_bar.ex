defmodule PrintClient.MenuBar do
  @moduledoc """
  Menubar that is shown as part of the main Window on Windows/Linux. In
  MacOS this Menubar appears at the very top of the screen.
  """

  import PrintClientWeb.Gettext
  use Desktop.Menu
  use PrintClientWeb, :verified_routes

  alias Desktop.Window

  @impl true
  def mount(menu) do
    {:ok, menu}
  end

  @impl true
  def handle_info("", menu) do
    {:noreply, menu}
  end

  @impl true
  def handle_event("observer", menu) do
    :observer.start()
    {:noreply, menu}
  end

  @impl true
  def handle_event("quit", menu) do
    Window.quit()
    {:noreply, menu}
  end

  @impl true
  def handle_event("browser", menu) do
    Window.prepare_url(~p"/")
    |> :wx_misc.launchDefaultBrowser()

    {:noreply, menu}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <menubar>
      <%= if Desktop.OS.type() != MacOS do %>
        <menu label={gettext("File")}>
          <item onclick="quit">{gettext("Quit")}</item>
        </menu>
      <% end %>

      <%= if Enum.member?([:dev,:test], Application.get_env(:print_client, :env)) do %>
        <menu label={gettext("Extra")}>
          <item onclick="observer">{gettext("Show Observer")}</item>
          <item onclick="browser">{gettext("Open Browser")}</item>
        </menu>
      <% end %>
    </menubar>
    """
  end
end
