defmodule PrintClientWeb.IiqSearchLive do
  use PrintClientWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    expanded = params["expanded"] == "true"

    socket =
      socket
      |> assign(expand_sidebar: expanded)
      |> assign_query_form()
      |> assign_label_values()
      |> maybe_resize_window()
      |> save_tab_state(expanded)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "grid gap-4",
      @expand_sidebar && "grid-cols-[21rem_1fr]"
    ]}>
      <div class="text-left">
        <div class="flex flex-row justify-between items-center">
          <.header>Label Printing</.header>
          <button type="button" class="btn btn-ghost btn-sm" phx-click="toggle_sidebar">
            <%= if @expand_sidebar do %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="m18.75 4.5-7.5 7.5 7.5 7.5m-6-15L5.25 12l7.5 7.5"
                />
              </svg>
            <% else %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="m5.25 4.5 7.5 7.5-7.5 7.5m6-15 7.5 7.5-7.5 7.5"
                />
              </svg>
            <% end %>
          </button>
        </div>

        <.form for={@query}>
          <div class="flex flex-row items-stretch">
            <.input
              type="select"
              options={@query.source["fields"]}
              tabindex="0"
              field={@query["selected_field"]}
              style="border-radius: 0.5rem 0 0 0.5rem;"
            />
            <.input
              type="text"
              style="margin-left: -1px; margin-right: -0.5rem; border-radius: 0; width: 100%;"
              tabindex="0"
              field={@query["query"]}
              placeholder={gettext("Enter a search query")}
            />
            <button
              type="submit"
              class={[
                "-ml-[2px] mt-2 p-2 block rounded-r-lg focus:ring-0 sm:text-sm sm:leading-6 border",
                "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
                "dark:phx-no-feedback:border-zinc-900 dark:phx-no-feedback:focus:border-zinc-800",
                "dark:bg-zinc-900 text-base-content hover:bg-zinc-200 dark:hover:bg-zinc-800",
                "active:bg-zinc-300 dark:active:bg-zinc-800",
                "border-zinc-300 focus:border-zinc-400 dark:border-zinc-900 dark:focus:border-zinc-800"
              ]}
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
                />
              </svg>
            </button>
          </div>
        </.form>

        <.hr class="mb-3 mt-4" />

        <.form for={@label} phx-submit="print">
          <div class="grid grid-cols-[2fr_3fr] items-center">
            <span>Owner</span>
            <.input
              type="text"
              field={@label[:owner]}
              required={@label[:action].value in ["both", "owner"]}
            />
            <span>Asset Tag</span>
            <.input
              type="text"
              field={@label[:asset]}
              required={@label[:action].value in ["both", "asset"]}
            />
            <span>Serial Number</span>
            <.input
              type="text"
              field={@label[:serial]}
              required={@label[:action].value in ["both", "asset"]}
            />
          </div>
          <.hr class="mb-3 mt-4" />

          <.input type="button-group" field={@label[:action]} options={@label_actions} />

          <.button type="submit" class="w-full grow mt-2"><%= gettext("Print Label(s)") %></.button>
        </.form>
      </div>
      <%= if @expand_sidebar do %>
        <div class="grow w-full bg-red-50 dark:bg-red-700 h-full"></div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_params(params, _uri, socket) do
    expanded = params["expanded"] == "true"

    {:noreply,
     socket
     |> assign(expand_tab: expanded)
     |> maybe_resize_window()
     |> save_tab_state(expanded)}
  end

  @impl true
  def handle_event("query", %{"query" => query, "field" => field}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    new_state = not socket.assigns.expand_sidebar

    {:noreply,
     socket
     |> maybe_resize_window()
     |> save_tab_state(new_state)}
  end

  @impl true
  def handle_event("print", params, socket) do
    form = to_form(%{"owner" => "", "asset" => "", "serial" => "", "action" => params["action"]})

    socket =
      socket
      |> assign(label: form)

    {:noreply, socket}
  end

  defp maybe_resize_window(socket) do
    {w, h} = PrintClient.Window.Print.opts()[:size]

    if socket.assigns.expand_sidebar do
      PrintClient.Window.Print.set_fixed_size({w + 300, h})
    else
      PrintClient.Window.Print.set_fixed_size({w, h})
    end

    socket
  end

  defp save_tab_state(socket, new_state) do
    old_state = socket.assigns.expand_sidebar

    dbg({old_state, new_state})

    route = fn params ->
      PrintClientWeb.Router.Helpers.live_path(
        PrintClientWeb.Endpoint,
        PrintClientWeb.IiqSearchLive,
        params
      )
    end

    cond do
      old_state and not new_state ->
        socket
        |> push_patch(to: route.(expanded: false))

      not old_state and new_state ->
        socket
        |> push_patch(to: route.(expanded: true))

      true ->
        socket
    end
    |> assign(expand_sidebar: new_state)
  end

  defp assign_query_form(socket) do
    form =
      %{
        "fields" => ["asset", "owner", "serial"],
        "selected_field" => "asset",
        "query" => ""
      }
      |> to_form()

    socket
    |> assign(query: form)
  end

  defp assign_label_values(socket) do
    form = to_form(%{owner: "", asset: "", serial: "", action: ""})

    socket
    |> assign(label: form)
    |> assign(label_actions: [Owner: "owner", Both: "both", Asset: "asset"])
  end
end
