defmodule PrintClientWeb.DashboardLive do
  use PrintClientWeb, :live_view

  @links [
    {"#", "Dashboard", "hero-home",
    """
      You are here.
    """},
    {"/views", "Views", "hero-rectangle-stack",
    """
    Views combine label templates with printers for saved printing experiences.
    """},
    {"/printers", "Printers", "hero-printer",
    """
    Update saved printers or delete existing printers.
    """},
    {"/templates", "Templates", "hero-photo",
    """
    View current templates, or update template search paths.
    """},
    {"/settings", "Settings", "hero-cog",
    """
    Application preferences and API integrations.
    """},
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(links: @links)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Dashboard
        <:subtitle>Browse the application</:subtitle>
      </.header>
      <div class="grid grid-cols-1 grid-rows-[1fr] lg:grid-cols-2 gap-4 lg:gap-8">
        <a :for={{href, label, icon, desc} <- @links} href={href} class="group">
          <div class="group-hover:bg-base-300 transition duration-150 card card-side w-full h-full bg-base-100 shadow-sm items-center justify-center">
            <figure class="p-4 sm:p-8">
              <.icon name={icon <> "-solid"} />
            </figure>
            <div class="card-body mb-auto">
              <h2 class="card-title">{label}</h2>
              <p>{desc}</p>
            </div>
          </div>
        </a>
      </div>
    </Layouts.app>
    """
  end
end
