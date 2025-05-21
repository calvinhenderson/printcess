defmodule PrintClientWeb.ApiSearchComponent do
  use PrintClientWeb, :html

  require Logger

  attr :field, Phoenix.HTML.FormField
  attr :results, :list, default: []
  attr :loading, :boolean, default: false
  attr :error, :any, default: nil
  attr :rest, :global

  def search(assigns) do
    ~H"""
    <div class={"group-[#{@field.name}]"}>
      <!-- Form Input -->
      <.label for={@field.id}>{normalize_field_name(@field.name)}</.label>
      <div class="relative flex flex-row border-[1px] border-zinc-300 justify-space-between items-center px-2 gap-0 rounded-md">
        <.icon name="hero-magnifying-glass-mini" />

        <input
          {@rest}
          type="text"
          class="h-12 w-full border-none focus:ring-0 text-gray-800 placeholder-gray-400 sm:text-sm"
          placeholder={"Search for or enter a #{normalize_field_name(@field.name, false)}"}
          role="combobox"
          aria-expanded="false"
          aria-controls="options"
          spellcheck="false"
          autocomplete="off"
          name={@field.name}
          value={Phoenix.HTML.Form.normalize_value("text", @field.value)}
        />
      </div>
      <.error
        :for={msg <- Enum.map(@field.errors, &translate_error/1)}
        :if={Phoenix.Component.used_input?(@field)}
      >
        {msg}
      </.error>
      
    <!-- Query Results -->
      <ul
        class={[
          "hidden group-focus-within:visible",
          "-mb-2 py-2 text-sm text-gray-800 flex space-y-2 flex-col",
          "max-h-[90pt] overflow-y-scroll rounded-md overflow-x-clip",
          if(is_nil(@error) and @results != [], do: "", else: "hidden")
        ]}
        id="options"
        role="listbox"
      >
        <div>
          <span :if={@loading}>Loading...</span>
          <%= for result <- @results do %>
            <%= case result do %>
              <% %{:id => id, :asset_number => asset, :serial_number => serial} -> %>
                <.result_item
                  id={id}
                  phx-value-id={id}
                  phx-value-value={if is_asset(@field), do: asset, else: serial}
                  phx-click="select-asset"
                >
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
              <% %{:id => id, :username => username, :display_name => name} -> %>
                <.result_item
                  id={id}
                  phx-value-id={id}
                  phx-value-value={username}
                  phx-click="select-user"
                >
                  <:icon><.icon name="hero-user-circle-solid" /></:icon>
                  <:info>
                    <span>{name} ({username})</span>
                  </:info>
                </.result_item>
            <% end %>
          <% end %>
        </div>
      </ul>
    </div>
    """
  end

  # --- Internal HTML Helpers ---

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the result item container"

  slot :icon, doc: "the optional slot that renders in the result icon"
  slot :info, doc: "the slot that renders the result info"

  defp result_item(assigns) do
    ~H"""
    <li
      class={[
        "cursor-default select-none first:rounded-t-md last:rounded-b-md px-4 py-2",
        "border-b-2 border-zinc-200 last:border-none",
        "text-xl bg-zinc-100 hover:bg-zinc-800 hover:text-white hover:cursor-pointer",
        "flex flex-row gap-4 items-center"
      ]}
      role="option"
      tabindex="1"
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

  defp is_asset(%Phoenix.HTML.FormField{field: field}) when field in [:asset],
    do: true

  defp is_asset(_), do: false

  defp normalize_field_name(name, capitalize \\ true) when is_binary(name) do
    case Regex.named_captures(~r/^[^\[]*\[(?<name>[^\]]*)\].*$/, name) do
      %{"name" => name} -> if capitalize, do: String.capitalize(name), else: name
      other -> name
    end
  end
end
