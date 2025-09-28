defmodule PrintClientWeb.SettingsLive do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.Settings

  @sections [
    %{
      id: :preferences,
      title: "User Preferences",
      icon: "hero-paint-brush-solid",
      module: Settings.UserPreferencesComponent
    },
    %{
      id: :api,
      title: "API Settings",
      icon: "hero-paper-airplane",
      module: Settings.ApiComponent
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(sections: @sections)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-4">
        <%= for %{id: id, title: title, icon: icon, module: mod} <- @sections do %>
          <div class="border-2 rounded-lg border-base-300 p-6">
            <.live_component id={id} module={mod} />
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
