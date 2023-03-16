defmodule PrintClient.Menu do
  @moduledoc """
  Action Menu for the taskbar icon.
  """
  import PrintClientWeb.Gettext

  use Desktop.Menu
  alias Desktop.Menu

  def mount(menu) do
    # This impure function sets the icon externally through wxWidgets
    Menu.set_icon(menu, {:file, "icon32x32.png"})

    {:ok, menu}
  end

  def handle_info(_, menu) do
    {:noreply, menu}
  end

  def handle_event("quit", menu), do:
    Desktop.Window.quit() |> then(fn _ -> {:noreply, menu} end)

  def handle_event("show", menu), do:
    Desktop.Window.show(PrintClientWindow) |> then(fn _ -> {:noreply, menu} end)

  def handle_event("hide", menu), do:
    Desktop.Window.hide(PrintClientWindow) |> then(fn _ -> {:noreply, menu} end)

   def render(assigns) do
    ~H"""
    <menu>
      <item onclick="show"><%= gettext "Show" %></item>
      <item onclick="hide"><%= gettext "Hide" %></item>
      <hr/>
      <item onclick="quit"><%= gettext "Quit" %></item>
    </menu>
    """
  end
end
