defmodule PrintClientWeb.SettingsLive do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.Settings

  @tabs [
    %{
      id: :preferences,
      href: "/settings",
      title: "User Preferences",
      icon: "hero-paint-brush-solid",
      module: Settings.UserPreferencesComponent
    },
    %{
      id: :printers,
      href: "/settings/printers",
      title: "Printer Settings",
      icon: "hero-printer-solid",
      module: Settings.PrinterComponent
    },
    %{
      id: :api,
      href: "/settings/api",
      title: "API Settings",
      icon: "hero-paper-airplane",
      module: Settings.ApiComponent
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    tab = Enum.find(@tabs, &(&1.id == socket.assigns.live_action))

    {:ok,
     socket
     |> assign(tabs: @tabs)
     |> assign_tab(tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="tabs tabs-border">
        <%= for %{id: id, title: title, href: href, icon: icon, module: mod} <- @tabs do %>
          <a
            href={href}
            class={[
              "tab gap-1",
              @tab.id == id && "tab-active"
            ]}
          >
            <.icon name={icon} />
            {title}
          </a>
          <div :if={@tab.id == id} class="tab-content bg-base-100 border-base-300 p-6">
            <.live_component id={id} module={mod} />
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp assign_tab(socket, nil), do: assign_tab(socket, :preferences)

  defp assign_tab(socket, tab) do
    socket
    |> assign(:tab, tab)
    |> assign(page_title: tab.title)
  end
end
