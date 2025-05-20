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

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title default="PrintClientWeb" suffix=" · Phoenix Framework">
          {assigns[:page_title]}
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
        <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4">
        </script>
      </head>
      <body class="bg-white">
        {@inner_content}
      </body>
    </html>
    """
  end

  attr :flash, :map, required: true, doc: "the flash"
  slot :actions, doc: "actions to show in the top right of the header"
  slot :inner_block, doc: "the inner page content"

  def app(assigns) do
    ~H"""
    <div class="grid [grid-template-areas:'header_header''aside_main''footer_footer'] grid-cols-[50px_1fr] grid-rows-[auto_1fr] min-h-screen bg-gray-200">
      <header class="px-4 sm:px-6 lg:px-8 [grid-area:header]">
        <div class="flex items-center justify-between py-2 text-sm">
          <div class="flex items-center gap-4">
            <p class="bg-brand/5 text-brand rounded-full px-2 font-medium leading-6">
              v{Application.spec(:print_client, :vsn)}
            </p>
          </div>
          <div class="flex items-center gap-4 font-semibold leading-6 text-zinc-900">
            {render_slot(@actions)}
          </div>
        </div>
      </header>
      <div class="[grid-area:aside] flex flex-col gap-0 justify-start items-center py-1">
        <.link href="/" class="p-2 rounded-md hover:bg-gray-300">
          <.icon name="hero-home-solid" />
        </.link>
        <span class="flex-grow" />
        <.link href="/settings" class="p-2 rounded-md hover:bg-gray-300">
          <.icon name="hero-cog-solid" />
        </.link>
      </div>
      <main class="[grid-area:main] bg-white rounded-tl-lg">
        <.flash_group flash={@flash} />
        <div class="p-2">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end
end
