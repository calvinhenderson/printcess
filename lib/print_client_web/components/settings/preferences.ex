defmodule PrintClientWeb.Settings.UserPreferencesComponent do
  use PrintClientWeb, :live_component

  alias PrintClient.Settings

  require Logger

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign_settings(Settings.change_preferences())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@form}
        id="preferences-form"
        phx-submit="update"
        phx-change="validate"
        phx-debounce="200"
        phx-target={@myself}
        class="flex flex-col gap-6"
      >
        <div>
          <.input
            label={gettext("Interface Theme")}
            field={f[:theme]}
            type="select"
            options={@options}
            class="select select-bordered w-full"
          />
          <p class="text-xs text-base-content/50 mt-2">
            Choose a theme that matches your system or preference.
          </p>
        </div>

        <div class="flex justify-end pt-4 border-t border-base-100">
          <button class="btn btn-primary min-w-[120px]" onclick="window.location.reload()">
            Save Preferences
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
      Settings.change_preferences(params)

    socket =
      socket
      |> assign(form: to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("update", %{"config" => params}, socket) do
    socket =
      case Settings.save_preferences(params) do
        {:ok, _settings} ->
          socket
          |> assign_settings(Settings.change_preferences())

        {:error, changeset} ->
          socket
          |> assign_settings(changeset)
      end

    {:noreply, socket}
  end

  defp assign_settings(socket, changeset) do
    options =
      Settings.available_themes()
      |> Enum.map(&{to_string(&1) |> String.capitalize(), to_string(&1)})

    socket
    |> assign(form: changeset)
    |> assign(options: options)
  end
end
