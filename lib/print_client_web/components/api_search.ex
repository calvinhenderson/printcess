defmodule PrintClientWeb.ApiSearchComponent do
  use PrintClientWeb, :html

  alias Phoenix.LiveView.AsyncResult
  import PrintClientWeb.PrintComponents

  require Logger

  attr :field, Phoenix.HTML.FormField
  attr :results, AsyncResult, default: AsyncResult.loading()
  attr :debounce, :any, default: "500"
  attr :target, :any, required: true
  attr :rest, :global

  def search(assigns) do
    ~H"""
    <div id={@field.id <> "-container"} class="contents">
      <.dropdown results={@results} results-id={@field.id <> "-results"}>
        <:label>
          <span>{normalized_field_name(@field)}</span>
          <.input
            field={@field}
            type="text"
            spellcheck="off"
            autocomplete="off"
            phx-debounce={@debounce}
            placeholder={gettext("Lookup or enter a value")}
            phx-hook="Dropdown"
            data-dropdown-root={@field.id <> "-results"}
          />
        </:label>
        <!-- Query Results -->
        <:option :let={result}>
          <%= case result do %>
            <% %{:id => id, :asset => asset, :serial => serial} = result -> %>
              <.result_item
                id={id}
                tabindex="0"
                phx-value-id={id}
                phx-click="select"
                phx-target={@target}
              >
                <:icon>
                  <svg
                    class="size-4"
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
                  <div class="flex flex-col w-full">
                    <div class="flex flex-row gap-2 w-full">
                      <span>#{asset}</span>
                      <span>{serial}</span>
                      <span class="grow" />
                      <span>{Map.get(result, :location, "")}</span>
                      <span class="grow" />
                      <span :if={result.status} class="badge badge-neutral">
                        {Map.get(result, :status, "")}
                      </span>
                    </div>
                    <div class="flex flex-row gap-2 w-full">
                      <span>
                        Owner: {Map.get(result, :username, "") |> String.slice(0..16)}
                        {if Map.get(result, :username, "") |> String.length() > 16,
                          do: "...",
                          else: ""}
                      </span>
                      <span class="grow" />
                      <span>
                        {"#{Map.get(result, :manufacturer, "")} #{Map.get(result, :model, "")}"}
                      </span>
                    </div>
                  </div>
                </:info>
              </.result_item>
            <% %{:id => id, :username => username, :display_name => name} = result -> %>
              <.result_item
                id={id}
                tabindex="0"
                phx-click="select"
                phx-value-id={id}
                phx-target={@target}
              >
                <:icon><.icon name="hero-user-circle-solid" class="size-4" /></:icon>
                <:info class="grid grid-cols-[3fr_2fr]">
                  <div class="flex flex-col">
                    <span>
                      {name}
                    </span>
                    <span>{username}</span>
                  </div>
                  <div class="flex flex-col justify-between items-end">
                    <span :if={result.role} class="badge badge-neutral">
                      {Map.get(result, :role, "")}
                    </span>
                    <span>
                      {if is_nil(result.grade),
                        do: "",
                        else: "Grade #{result.grade}"}
                    </span>
                  </div>
                </:info>
              </.result_item>
          <% end %>
        </:option>
      </.dropdown>
    </div>
    """
  end

  # --- Internal HTML Helpers ---

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the result item container"

  slot :icon, doc: "the optional slot that renders in the result icon"

  slot :info, required: true, doc: "the slot that renders the result info" do
    attr :class, :string
  end

  defp result_item(assigns) do
    ~H"""
    <div class="flex flex-row" role="option" tabindex="1" {@rest}>
      <div class="w-8">
        {render_slot(@icon)}
      </div>
      <div class={["flex-grow flex flex-row gap-4", Enum.at(@info, 0) |> Map.get(:class, "")]}>
        {render_slot(@info)}
      </div>
    </div>
    """
  end

  defp normalized_field_name(field, capitalize \\ true) do
    ~r/^[^\[]*\[(?<name>[^\]]*)\].*$/
    |> Regex.named_captures(Map.get(field, :name, ""))
    |> case do
      %{"name" => name} ->
        name

      _other ->
        Map.get(field, :name, "")
    end
    |> then(&if capitalize, do: String.capitalize(&1), else: &1)
  end
end
