defmodule PrintClientWeb.Settings.ApiComponent do
  use PrintClientWeb, :live_component

  alias PrintClient.Settings

  require Logger

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(form: to_form(Settings.change_api()))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ul class="list space-y-16">
      <li class="list-col">
        <.header>API Settings</.header>
        <.form
          :let={f}
          for={@form}
          id="api-form"
          phx-submit="update"
          phx-change="validate"
          phx-debounce="200"
          phx-target={@myself}
          class="space-y-8"
        >
          <.input
            label={gettext("Instance Name")}
            field={f[:instance]}
            placeholder="[INSTANCE].incidentiq.com"
          />
          <.input
            label={gettext("API Token")}
            field={f[:token]}
            placeholder="User Token from Admin > Developer Tools"
          />
          <.input
            label={gettext("Product ID")}
            field={f[:product_id]}
            placeholder="Product ID (ticketing, facilities, etc.)"
          />
          <div class="flex flex-row gap-4">
            <button class="btn btn-primary grow" type="submit">{gettext("Save")}</button>
          </div>
        </.form>
      </li>
    </ul>
    """
  end

  # --- GENERAL SETTINGS ---

  @impl true
  def handle_event(event, params, socket)

  def handle_event("validate", %{"config" => params}, socket) do
    changeset =
      Settings.change_api(params)

    socket =
      socket
      |> assign(form: to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("update", %{"config" => params}, socket) do
    changeset =
      case Settings.save_api(params) do
        {:ok, _settings} -> Settings.change_api(%{})
        {:error, changeset} -> changeset
      end

    {:noreply, assign_settings(socket, changeset)}
  end

  defp assign_settings(socket, changeset) do
    socket
    |> assign(form: changeset)
  end
end
