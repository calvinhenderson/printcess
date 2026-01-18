defmodule PrintClientWeb.ViewLive.Form do
  use PrintClientWeb, :live_view

  use Ecto.Schema

  embedded_schema do
    field :iiq_assign_assets, :boolean
  end

  def changeset(api_settings, attrs) do
    api_settings
    |> Ecto.Changeset.cast(attrs, [:iiq_assign_assets])
    |> Ecto.Changeset.validate_required([:iiq_assign_assets])
  end

  alias PrintClient.Label.Template
  alias PrintClient.Views
  alias PrintClient.Views.View
  alias PrintClient.Settings

  alias PrintClientWeb.PrintComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto pb-20">
        <div class="mb-8 border-b border-base-200 pb-6">
          <h1 class="text-3xl font-bold text-base-content">{@page_title}</h1>
          <p class="text-base-content/60 mt-2">
            Configure the visual layout and print destinations for this view.
          </p>
        </div>

        <.form for={@form} id="view-form" phx-change="validate" phx-submit="save" class="relative">
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-start">
            <div class="lg:col-span-5 flex flex-col gap-4 sticky top-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="bg-primary/10 text-primary p-2 rounded-lg">
                  <.icon name="hero-photo" class="w-5 h-5" />
                </span>
                <div>
                  <h3 class="font-bold text-lg leading-tight">Label Template</h3>
                  <p class="text-xs text-base-content/50">Select the visual design</p>
                </div>
              </div>

              <PrintComponents.template_select field={@form[:template]} options={@templates} />
            </div>

            <div class="lg:col-span-7 flex flex-col gap-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="bg-primary/10 text-primary p-2 rounded-lg">
                  <.icon name="hero-printer" class="w-5 h-5" />
                </span>
                <div>
                  <h3 class="font-bold text-lg leading-tight">Destinations</h3>
                  <p class="text-xs text-base-content/50">Select target devices</p>
                </div>
              </div>

              <PrintComponents.printer_select
                field={@form[:printer_ids]}
                id="view-form-printers"
                multiple={true}
                value={changeset_value_ids(@form[:printers].value)}
                options={@printers}
              />
            </div>

            <div class="lg:col-span-7 flex flex-col gap-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="bg-primary/10 text-primary p-2 rounded-lg">
                  <.icon name="hero-cog" class="w-5 h-5" />
                </span>
                <div>
                  <h3 class="font-bold text-lg leading-tight">API Settings</h3>
                  <p class="text-xs text-base-content/50">
                    Configure API integrations
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="fixed bottom-0 left-0 right-0 bg-base-100 border-t border-base-200 p-4 z-50 shadow-lg shadow-base-300">
            <div class="max-w-7xl mx-auto flex justify-end gap-3">
              <.button navigate={return_path(@return_to, @view)} class="btn-ghost">
                Cancel
              </.button>
              <.button phx-disable-with="Saving..." class="btn-primary min-w-[140px]">
                Save View
              </.button>
            </div>
          </div>
        </.form>
      </div>
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
    |> assign(:api_settings, to_form(changeset(%__MODULE__{}, view.api_settings)))
  end

  defp apply_action(socket, :new, _params) do
    view = %View{}

    socket
    |> assign(:page_title, "New View")
    |> assign(:view, view)
    |> assign(:form, to_form(Views.change_view(view)))
    |> assign(:api_settings, to_form(changeset(%__MODULE__{}, view.api_settings)))
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
