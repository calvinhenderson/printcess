defmodule PrintClientWeb.ApiSearchComponent do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  @impl true
  def handle_event("suggest", %{"query" => query}, socket) do
    Logger.debug("ApiSearchComponent: pulling suggestions for #{query}")
    assets = PrintClient.Assets.search(query)
    users = PrintClient.Users.search(query)
    results = assets ++ users

    dbg(results)

    {:noreply, socket |> assign(search_results: results)}
  end

  def handle_event(event, params, socket) do
    Logger.debug("ApiSearchComponent: got event #{inspect(event)} with params #{inspect(params)}")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form id={@id <> "-form"} phx-target={@myself} phx-change="suggest" phx-debounce="250">
      <.header>Query Form</.header>
      <.input
        type="text"
        id={@id <> "-query"}
        name="query"
        value={@search_query}
        placeholder="Start typing to search..."
        autocomplete="off"
        list={@id <> "-results"}
      />
      <datalist id={@id <> "-results"}>
        <%= for result <- @search_results do %>
          <%= case result do %>
            <% %{"AssetId" => id, "AssetNumber" => asset, "SerialNumber" => serial} -> %>
              <option
                value={asset}
                data-id={id}
                data-type="asset"
                phx-click="select"
                phx-target={@myself}
              >
                <span>Asset: {asset}, Serial: {serial}</span>
              </option>
            <% %{"UserId" => id, "Username" => username, "DisplayName" => display_name} -> %>
              <option
                value={display_name}
                data-id={id}
                data-type="user"
                phx-click="select"
                phx-target={@myself}
              >
                <span>{display_name} ({username})</span>
              </option>
            <% _ -> %>
          <% end %>
        <% end %>
      </datalist>
    </form>
    """
  end
end
