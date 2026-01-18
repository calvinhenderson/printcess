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
      <div class="max-w-4xl mx-auto pb-12">
        <div class="mb-8 border-b border-base-200 pb-6">
          <h1 class="text-3xl font-bold text-base-content">Settings</h1>
          <p class="text-base-content/60 mt-2">
            Manage application preferences and external integrations.
          </p>
        </div>

        <div class="flex flex-col gap-8">
          <%= for %{id: id, title: title, icon: icon, module: mod} <- @sections do %>
            <section id={id} class="card bg-base-100 shadow-sm border border-base-200 overflow-hidden">
              <div class="px-6 py-4 border-b border-base-200 bg-base-50/50 flex items-center gap-3">
                <div class="p-2 bg-primary/10 text-primary rounded-lg flex items-center justify-center">
                  <.icon name={icon} class="w-5 h-5" />
                </div>
                <h2 class="font-bold text-lg text-base-content">{title}</h2>
              </div>

              <div class="p-6 md:p-8">
                <.live_component id={id} module={mod} />
              </div>
            </section>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
