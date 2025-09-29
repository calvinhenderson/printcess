defmodule PrintClientWeb.ViewLive.Form do
  use PrintClientWeb, :live_view

  alias PrintClient.Label.Template
  alias PrintClient.Views
  alias PrintClient.Views.View
  alias PrintClient.Settings

  alias PrintClientWeb.PrintComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage view records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="view-form" phx-change="validate" phx-submit="save">
        <PrintComponents.template_select
          field={@form[:template]}
          label="Template"
          options={@templates}
        />
        <PrintComponents.printer_select
          field={@form[:printer_ids]}
          id="view-form-printers"
          multiple={true}
          label="Printers"
          value={changeset_value_ids(@form[:printers].value)}
          options={@printers}
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save View</.button>
          <.button navigate={return_path(@return_to, @view)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:templates, Template.load_templates())
     |> assign(:printers, Settings.all_printers())}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    view = Views.get_view!(id)

    socket
    |> assign(:page_title, "Edit View")
    |> assign(:view, view)
    |> assign(:form, to_form(Views.change_view(view)))
  end

  defp apply_action(socket, :new, _params) do
    view = %View{}

    socket
    |> assign(:page_title, "New View")
    |> assign(:view, view)
    |> assign(:form, to_form(Views.change_view(view)))
  end

  @impl true
  def handle_event("validate", %{"view" => view_params}, socket) do
    changeset = Views.change_view(socket.assigns.view, view_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"view" => view_params}, socket) do
    save_view(socket, socket.assigns.live_action, view_params)
  end

  defp save_view(socket, _action, view_params) do
    case Views.save_view(socket.assigns.view, view_params) do
      {:ok, view} ->
        {:noreply,
         socket
         |> put_flash(:info, "View updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, view))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _view), do: ~p"/views"
  defp return_path("show", view), do: ~p"/views/#{view}"

  defp changeset_value_ids(%Ecto.Changeset{data: %{id: id}}), do: to_string(id)
  defp changeset_value_ids(%{id: id}), do: to_string(id)

  defp changeset_value_ids([changeset | rest]),
    do: [changeset_value_ids(changeset) | changeset_value_ids(rest)]

  defp changeset_value_ids([]), do: []
end
