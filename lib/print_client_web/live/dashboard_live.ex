defmodule PrintClientWeb.DashboardLive do
  use PrintClientWeb, :live_view

  @links [
    {"/views", "Views", "hero-rectangle-stack-solid",
     """
     Views combine label templates with printers for saved printing experiences.
     """},
    {"/jobs", "Jobs", "hero-queue-list-solid",
     """
     View the list of pending and completed print jobs.
     """},
    {"/printers", "Printers", "hero-printer-solid",
     """
     Update saved printers or delete existing printers.
     """},
    {"/templates", "Templates", "hero-photo-solid",
     """
     View current templates, or update template search paths.
     """},
    {"/settings", "Settings", "hero-cog-solid",
     """
     Application preferences and API integrations.
     """}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(links: @links)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-base-content">Dashboard</h1>
        <p class="text-base-content/60">Browse the application modules</p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <.link
          :for={{href, label, icon, desc} <- @links}
          navigate={href}
          class="card bg-base-100 shadow-sm border border-base-200 hover:shadow-md hover:border-primary/50 transition-all duration-200 group"
        >
          <div class="card-body flex-row items-center gap-4 p-6">
            <div class="rounded-2xl bg-primary/10 p-4 text-primary group-hover:scale-110 group-hover:bg-primary group-hover:text-primary-content transition-all duration-300">
              <.icon name={icon} class="w-8 h-8" />
            </div>

            <div class="flex-1 min-w-0">
              <h2 class="card-title text-lg mb-1">{label}</h2>
              <p class="text-sm text-base-content/70 leading-snug">
                {desc}
              </p>
            </div>

            <div class="text-base-300 group-hover:text-primary group-hover:translate-x-1 transition-all duration-200">
              <.icon name="hero-chevron-right-solid" class="w-6 h-6" />
            </div>
          </div>
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
