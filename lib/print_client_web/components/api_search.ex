defmodule PrintClientWeb.ApiSearchComponent do
  use PrintClientWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("suggest", %{"search_query" => query}, socket) do
    assets = PrintClient.Assets.search(query)
    users = PrintClient.Users.search(query)
    results = assets ++ users

    {:noreply, socket |> assign(search_results: results)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.input
        type="text"
        id="search_query"
        name="search_query"
        phx-debounce="250"
        phx-change="suggest"
        value={@search_query}
        label="Search for a User or an Asset"
        placeholder="Start typing to search..."
        autocomplete="off"
      />
      <datalist id="search_results_list">
        <%= for result <- @search_results do %>
          <%= case result do %>
            <% %{"AssetId" => id, "AssetNumber" => asset, "SerialNumber" => serial} -> %>
              <option value={asset} data-id={id} data-type="asset" phx-click="select">
                <span>Asset: {asset}, Serial: {serial}</span>
              </option>
            <% %{"UserId" => id, "Username" => username, "DisplayName" => display_name} -> %>
              <option value={display_name} data-id={id} data-type="asset" phx-click="select">
                <span>{display_name} ({username})</span>
              </option>
            <% _ -> %>
          <% end %>
        <% end %>
      </datalist>
      <p class="mt-1 text-sm text-gray-500">
        Select a result from the suggestions to auto-fill the fields below.
      </p>
      <div
        :if={@search_results && length(@search_results) > 0}
        class="mt-2 border border-gray-300 rounded-md shadow-sm max-h-60 overflow-y-auto"
      >
        <ul>
          <%= for result <- @search_results do %>
            <li
              class="p-2 hover:bg-gray-100 cursor-pointer"
              phx-click="select_search_result"
              phx-value-id={result.id}
              phx-value-type={result.type}
              phx-value-username={result.username}
              phx-value-asset-name={result.asset_name}
              phx-value-serial-number={result.serial_number}
            >
              <strong>{result.display_name}</strong>
              <span class="text-xs text-gray-500">({result.type})</span>
              <p class="text-sm text-gray-600">
                <%= case result.type do %>
                  <% "user" -> %>
                    Username: {result.username}
                  <% "asset" -> %>
                    Asset: {result.asset_name}, Serial: {result.serial_number}
                  <% _ -> %>
                <% end %>
              </p>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
