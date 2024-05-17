defmodule PrintClientWeb.IiqSearchLive do
  alias PrintClient.Settings
  use PrintClientWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    expanded = params["expanded"] == "true"
    printers = Settings.all_printers()

    socket =
      socket
      |> assign_printer()
      |> assign(expand_sidebar: expanded)
      |> assign_query_form()
      |> assign_label_values()
      |> maybe_resize_window()
      |> save_tab_state(expanded)

    {:ok, socket}
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
  def handle_event("select-printer", %{"active" => selected}, socket) do
    {:noreply,
     socket
     |> assign_printer(selected)}
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
    saved_params = Map.take(params, ["action"])

    {:noreply,
     socket
     |> assign(label_params: saved_params)}
  end

  @impl true
  def handle_event("update-label", params, socket) do
    {:noreply,
     socket
     |> assign(label_params: params)
     |> assign_label_values()}
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
    params = Map.get(socket.assigns, :label_params, %{})

    owner = Map.get(params, "owner", "")
    asset = Map.get(params, "asset", "")
    serial = Map.get(params, "serial", "")
    action = Map.get(params, "action", "")

    form = to_form(%{"owner" => owner, "asset" => asset, "serial" => serial, "action" => action})

    socket
    |> assign(label: form)
    |> assign(label_actions: [Owner: "owner", Both: "both", Asset: "asset"])
  end

  defp assign_printer(socket, selected \\ nil) do
    printers = Settings.all_printers()

    selected =
      (cond do
        printer = Enum.find(printers, & &1.name == selected) ->
          printer
        printer = Enum.find(printers, & &1.selected) ->
          printer
        true ->
          [printer | _] = Enum.take(printers, 1)
          printer
      end)

    form = to_form(%{"active" => selected.name, "options" => Enum.map(printers, & &1.name)})

    socket
    |> assign(printer: selected)
    |> assign(printer_form: form)
  end
end
