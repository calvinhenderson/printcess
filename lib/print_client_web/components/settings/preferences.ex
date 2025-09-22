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
    <ul class="list space-y-16">
      <li class="list-col">
        <.header>Preferences</.header>
        <.form
          :let={f}
          for={@form}
          id="preferences-form"
          phx-submit="update"
          phx-change="validate"
          phx-debounce="200"
          phx-target={@myself}
          class="space-y-8"
        >
          <.input label={gettext("Theme")} field={f[:theme]} type="select" options={@options} />
          <div class="flex flex-row justify-baseline gap-4">
            <button class="btn btn-primary grow" onclick="window.location.reload()">Save</button>
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
      Settings.change_preferences(params)
      |> dbg()

    socket =
      socket
      |> assign(form: to_form(changeset))
      |> dbg()

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
