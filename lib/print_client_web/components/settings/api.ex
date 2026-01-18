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
    <div>
      <.form
        :let={f}
        for={@form}
        id="api-form"
        phx-submit="update"
        phx-change="validate"
        phx-debounce="200"
        phx-target={@myself}
        class="flex flex-col gap-6"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="w-full">
            <.input
              label={gettext("Instance Name")}
              field={f[:instance]}
              placeholder="example.incidentiq.com"
            />
            <p class="text-xs text-base-content/50 mt-1">Your dedicated instance URL.</p>
          </div>

          <div class="w-full">
            <.input
              label={gettext("Product ID")}
              field={f[:product_id]}
              placeholder="e.g. ticketing, assets"
            />
          </div>
        </div>

        <div>
          <.input
            label={gettext("API Access Token")}
            field={f[:token]}
            type="password"
            value={if f[:token].value, do: "****************", else: ""}
            placeholder="Paste your User Token here"
          />
          <p class="text-xs text-base-content/50 mt-1">
            Generated via Admin > Developer Tools. Kept secure.
          </p>
        </div>

        <div class="flex justify-end pt-4 border-t border-base-100 mt-2">
          <button class="btn btn-primary min-w-[120px]" type="submit">
            {gettext("Save Configuration")}
          </button>
        </div>
      </.form>
    </div>
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
