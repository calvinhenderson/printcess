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
      <.dropdown results={@results}>
        <:label>
          <span>{normalized_field_name(@field)}</span>
          <.input
            field={@field}
            type="text"
            spellcheck="off"
            autocomplete="off"
            phx-debounce={@debounce}
            placeholder={gettext("Lookup or enter a value")}
          />
        </:label>
        <!-- Query Results -->
        <:option :let={result}>
          <%= case result do %>
            <% %{:id => id, :asset => asset, :serial => serial} = result -> %>
              <.result_item id={id} phx-value-id={id} phx-click="select" phx-target={@target}>
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
                  <div class="flex flex-col">
                    <div class="flex flex-row gap-2">
                      <span>
                        {"#{Map.get(result, :manufacturer, "")} #{Map.get(result, :model, "")}"}
                      </span>
                      <span>
                        Owner: {Map.get(result, :username, "")}
                      </span>
                    </div>
                    <div class="flex flex-row gap-2">
                      <span>#{asset}</span>
                      <span>{serial}</span>
                    </div>
                  </div>
                </:info>
              </.result_item>
            <% %{:id => id, :username => username, :display_name => name} = result -> %>
              <.result_item id={id} phx-click="select" phx-value-id={id} phx-target={@target}>
                <:icon><.icon name="hero-user-circle-solid" class="size-4" /></:icon>
                <:info>
                  <span>
                    {name} ({username}) {# {result.grade}"
                    if is_nil(result.grade), do: "", else: "Grade #{result.grade}"}
                  </span>
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
  slot :info, doc: "the slot that renders the result info"

  defp result_item(assigns) do
    ~H"""
    <div class="flex flex-row" role="option" tabindex="1" {@rest}>
      <div class="w-8">
        {render_slot(@icon)}
      </div>
      <div class="flex-grow flex flex-row gap-4">
        {render_slot(@info)}
      </div>
    </div>
    """
  end

  defp is_asset(%Phoenix.HTML.FormField{field: field}) when field in [:asset],
    do: true

  defp is_asset(_), do: false

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

  defp get_results(%AsyncResult{result: options}) when is_list(options), do: options
  defp get_results(_), do: []
end
