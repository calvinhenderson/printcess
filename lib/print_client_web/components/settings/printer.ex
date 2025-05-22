defmodule PrintClientWeb.Settings.PrinterComponent do
  use PrintClientWeb, :live_component

  alias PrintClient.Printer.Discovery
  alias PrintClient.Printer
  alias PrintClient.Settings

  require Logger

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign_printers(nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ul class="list space-y-16">
      <li class="list-col">
        <fieldset class="fieldset border-base-200 rounded-box border p-4">
          <legend>Printer Settings</legend>
          <.form
            for={@printer_form}
            phx-submit="update"
            phx-change="validate"
            phx-debounce="200"
            phx-target={@myself}
            class="form-control gap-2 w-full grow mt-6"
          >
          </.form>
        </fieldset>
      </li>
    </ul>
    """
  end

  # --- FORM EVENTS ---

  @impl true
  def handle_event("validate", params, socket) do
    socket.assigns.printer
    |> Settings.change_printer(params)
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, _printer} ->
        socket

      {:error, changeset} ->
        socket
        |> assign(printer_form: to_form(changeset))
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("update", params, socket) do
    changeset = Settings.change_printer(socket.assigns.printer, params)

    socket.assigns.printer
    |> Settings.save_printer(changeset)
    |> case do
      {:ok, _printer} ->
        socket |> assign_printers(nil)

      {:error, changeset} ->
        socket
        |> assign(printer_form: to_form(changeset))
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("select", %{"id" => printer_id}, socket) do
    {:noreply, socket |> assign_printers(printer_id)}
  end

  def handle_event("select", _params, socket) do
    {:noreply, socket |> assign_printers(nil)}
  end

  def handle_event("delete", _params, socket) do
    printer = socket.assigns.printer

    Settings.delete_printer(socket.assigns.printer)
    |> case do
      {:ok, _printer} ->
        socket
        |> put_flash(:info, "Deleted printer: #{printer.name}")
        |> assign_printers(nil)

      {:error, changeset} ->
        Logger.error("SettingsLive: Failed to delete printer: #{inspect(changeset)}")

        socket
        |> put_flash(:error, "Failed to delete printer: #{printer.name}")
        |> assign(printer_form: to_form(changeset))
    end
    |> then(&{:noreply, &1})
  end

  defp assign_printers(socket, printer, changeset \\ nil)

  defp assign_printers(socket, nil, changeset),
    do: assign_printers(socket, %Settings.Printer{}, changeset)

  defp assign_printers(socket, printer, changeset) do
    printers = Settings.all_printers()

    changeset =
      case changeset do
        nil ->
          Settings.change_printer(printer)

        changeset ->
          changeset
      end

    socket
    |> assign(printers: printers)
    |> assign(selected_printer: printer)
    |> assign(printer_form: to_form(changeset))
  end
end
