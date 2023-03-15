defmodule PrintClient.Menu do
  @moduledoc """
  Action Menu for the taskbar icon.
  """
  import PrintClientWeb.Gettext

  alias Phoenix.PubSub

  use Desktop.Menu
  alias Desktop.Menu

  def mount(menu) do
    # This impure function sets the icon externally through wxWidgets
    Menu.set_icon(menu, {:file, "icon.png"})

    {:ok, menu}
  end

  def handle_info(_, menu) do
    {:noreply, menu}
  end

  def handle_event("quit", menu), do:
    Desktop.Window.quit() |> then(fn _ -> {:noreply, menu} end)

  def handle_event("show", menu), do:
    Desktop.Window.show(PrintClientWindow) |> then(fn _ -> {:noreply, menu} end)

  def handle_event("text", menu) do
    PubSub.broadcast(:menu_action, "open text")
    Desktop.Window.show(PrintClientWindow)
    {:noreply, menu}
  end

  def handle_event("asset", menu) do
    PubSub.broadcast(:menu_action, "open asset")
    Desktop.Window.show(PrintClientWindow)
    {:noreply, menu}
  end

  def render(assigns) do
    ~H"""
    <menu>
      <item onclick="show"><%= gettext "Show" %></item>
      <hr/>
      <item onclick="text"><%= gettext "Text Label" %></item>
      <item onclick="asset"><%= gettext "Asset Label" %></item>
      <hr/>
      <item onclick="quit"><%= gettext "Quit" %></item>
    </menu>
    """
  end
end
