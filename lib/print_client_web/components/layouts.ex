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
    <div class="grid [grid-template-areas:'aside_header''aside_main'] grid-cols-[auto_1fr] grid-rows-[auto_1fr] min-h-screen bg-base-200">
      
    <!-- Header -->
      <header class="[grid-area:header] px-4 sm:px-6 lg:px-8 w-full flex flex-row flex-wrap justify-between items-center min-h-12 bg-base-300">
        <a onclick="maybeNavigateBack()" href="#" class="btn btn-ghost">
          <.icon name="hero-arrow-left-solid" class="w-3 h-3" /> Back
        </a>
        <span class="grow" />
        <div>
          {render_slot(@actions)}
        </div>
      </header>
      
    <!-- Sidebar navigation -->
      <nav class="[grid-area:aside] h-full bg-primary text-primary-content w-16 md:w-36">
        <div class="fixed w-16 md:w-36 p-1 h-screen flex flex-col gap-0 justify-start items-center overflow-x-hidden overflow-y-auto">
          <a href="/">
            <div class="w-full bg-gray-900/20 flex flex-col justify-center gap-1 px-4 py-2">
              <h2 class="w-full text-lg font-bold flex items-center justify-center md:justify-between">
                <.icon name="hero-printer-solid" /><span class="hidden md:inline">Printcess</span>
              </h2>
              <span class="badge badge-xs self-center md:self-end">
                v{Application.spec(:print_client, :vsn)}
              </span>
            </div>
          </a>
          <%= for item <- [
            {"/", "Printing", "hero-home-solid"},
            {"/settings/printers", "Printers", "hero-printer-solid"},
            {"/settings/templates", "Labels", "hero-photo-solid"},
            :spacer,
            {"/settings", "Settings", "hero-cog-solid"},
          ] do %>
            <%= case item do %>
              <% {href, label, icon} -> %>
                <a
                  href={href}
                  class="w-full px-1 md:px-4 py-2 flex flex-row justify-center items-center md:justify-start gap-2 btn btn-ghost"
                >
                  <.icon name={icon} />
                  <span class="hidden md:inline">{label}</span>
                </a>
              <% :spacer -> %>
                <span class="grow" />
            <% end %>
          <% end %>
        </div>
      </nav>
      
    <!-- Main content -->
      <main class="[grid-area:main] p-4 sm:p-8">
        <div class="container mx-auto">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    <.flash_group flash={@flash} />
    """
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
