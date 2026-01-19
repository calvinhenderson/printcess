defmodule PrintClientWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use PrintClientWeb, :controller` and
  `use PrintClientWeb, :live_view`.
  """
  use PrintClientWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the app layout

  ## Examples

  <Layouts.app flash={@flash}>
  <h1>Content</h1>
  </Layout.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :actions, required: false
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="[grid-template-areas:'aside_main'] grid grid-cols-[auto_1fr] grid-rows-[auto_1fr] min-h-screen bg-base-200">
      <nav class="[grid-area:'aside'] h-screen sticky top-0 z-20 flex-col justify-between items-center md:items-start overflow-y-auto bg-base-100 shadow-xl w-20 md:w-50 flex">
        <div class="py-6 md:p-6 flex items-center gap-3">
          <div class="bg-primary/10 p-2 rounded-lg text-primary">
            <.icon name="hero-printer-solid" class="w-8 h-8" />
          </div>
          <div class="hidden md:block">
            <h2 class="font-bold text-xl leading-tight">Printcess</h2>
            <span class="text-xs font-medium text-base-content/50">
              v{Application.spec(:print_client, :vsn)}
            </span>
          </div>
        </div>

        <ul class="menu menu-lg px-4 gap-2 w-full">
          <%= for {href, label, icon} <- [
            {"/", "Dashboard", "hero-home"},
            {"/views", "Views", "hero-rectangle-stack"},
            {"/jobs", "Jobs", "hero-queue-list"},
            {"/printers", "Printers", "hero-printer"},
            {"/templates", "Templates", "hero-photo"}
          ] do %>
            <li>
              <.link
                navigate={href}
                class={[
                  link_active?(@current_scope, href) &&
                    "active bg-primary text-primary-content font-semibold"
                ]}
              >
                <.icon name={icon} class="w-5 h-5" />
                <span class="hidden md:inline">{label}</span>
              </.link>
            </li>
          <% end %>
        </ul>

        <div class="mt-auto p-2 border-t border-base-200 w-full">
          <ul class="menu menu-lg w-full">
            <li>
              <.link
                navigate="/settings"
                class={[
                  link_active?(@current_scope, "/settings") &&
                    "active bg-primary text-primary-content font-semibold"
                ]}
              >
                <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
                <span class="hidden md:inline">Settings</span>
              </.link>
            </li>
          </ul>
        </div>
      </nav>

      <main class="[grid-area:'main'] h-full overflow-y-auto p-4 md:p-8">
        <div class="container mx-auto max-w-5xl">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp link_active?(%{path: path}, href) do
    cond do
      href == "/" and path == "/" -> true
      href != "/" and String.starts_with?(path, href) -> true
      true -> false
    end
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

  <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        class="flex p-2 cursor-pointer w-1/3"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
