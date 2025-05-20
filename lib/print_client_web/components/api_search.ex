defmodule PrintClientWeb.ApiSearchComponent do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, socket |> assign(query: ""), temporary_assigns: [results: []]}
  end

  @impl true
  def handle_event("suggest", %{"value" => query}, socket) do
    Logger.debug("ApiSearchComponent: pulling suggestions for #{query}")

    {:noreply,
     socket
     |> assign(query: query)
     |> assign(:results, [])
     |> assign(
       :results,
       (fn ->
          assets = PrintClient.Assets.search(query)
          users = PrintClient.Users.search(query)

          assets ++ users
        end).()
     )}
  end

  def handle_event(event, params, socket) do
    Logger.debug("ApiSearchComponent: got event #{inspect(event)} with params #{inspect(params)}")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>Query Form</.header>
      <.search_input value={@query} phx-target={@myself} phx-keyup="suggest" phx-debounce="250" />
      <.search_results target={@myself} results={@results} show={@results != [] and @query != ""} />
    </div>
    """
  end

  # --- Internal HTML Helpers ---

  attr :rest, :global

  defp search_input(assigns) do
    ~H"""
    <div class="relative flex flex-row border-[1px] border-zinc-300 justify-space-between items-center px-2 gap-0 rounded-md">
      <.icon name="hero-magnifying-glass-mini" />

      <input
        {@rest}
        type="text"
        class="h-12 w-full border-none focus:ring-0 text-gray-800 placeholder-gray-400 sm:text-sm"
        placeholder="Search the docs.."
        role="combobox"
        aria-expanded="false"
        aria-controls="options"
      />
    </div>
    """
  end

  attr :show, :boolean, default: false
  attr :results, :list, required: true
  attr :target, :any, default: nil, doc: "the phoenix socket to send click events to"

  defp search_results(assigns) do
    ~H"""
    <ul
      class={[
        "-mb-2 py-2 text-sm text-gray-800 flex space-y-2 flex-col",
        "max-h-[90pt] overflow-y-scroll rounded-md overflow-x-clip",
        if(@show, do: "", else: "hidden")
      ]}
      id="options"
      role="listbox"
    >
      <li
        :if={[] == @results}
        id="option-none"
        role="option"
        tabindex="-1"
        class="cursor-default select-none rounded-md px-4 py-2 text-xl"
      >
        No Results
      </li>

      <div :if={[] != @results}>
        <%= for result <- @results do %>
          <%= case result do %>
            <% %{"AssetId" => id, "AssetNumber" => asset, "SerialNumber" => serial} -> %>
              <.result_item id={id} data-id={id} phx-click="select-asset">
                <:icon>
                  <svg
                    class="w-6 h-6"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    data-darkreader-inline-fill=""
                    style="--darkreader-inline-fill: currentColor;"
                  >
                    <path d="M20 18c1.1 0 1.99-.9 1.99-2L22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2H0v2h24v-2h-4zM4 6h16v10H4V6z">
                    </path>
                  </svg>
                </:icon>
                <:info>
                  <span>Asset: {asset}</span>
                  <span>Serial: {serial}</span>
                </:info>
              </.result_item>
            <% %{"UserId" => id, "Username" => username, "DisplayName" => display_name} -> %>
              <.result_item id={id} data-id={id} phx-click="select-user">
                <:icon><.icon name="hero-user-circle-solid" /></:icon>
                <:info>
                  <span>{display_name} ({username})</span>
                </:info>
              </.result_item>
            <% _ -> %>
              {inspect(result)}
          <% end %>
        <% end %>
      </div>
    </ul>
    """
  end

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the result item container"

  slot :icon, doc: "the optional slot that renders in the result icon"
  slot :info, doc: "the slot that renders the result info"

  defp(result_item(assigns)) do
    ~H"""
    <li
      class={[
        "cursor-default select-none first:rounded-t-md last:rounded-b-md px-4 py-2",
        "border-b-2 border-zinc-200 last:border-none",
        "text-xl bg-zinc-100 hover:bg-zinc-800 hover:text-white hover:cursor-pointer",
        "flex flex-row gap-4 items-center"
      ]}
      role="option"
      tabindex="-1"
      {@rest}
    >
      <div class="w-8">
        {render_slot(@icon)}
      </div>
      <div class="flex-grow flex flex-row gap-4">
        {render_slot(@info)}
      </div>
    </li>
    """
  end
end
