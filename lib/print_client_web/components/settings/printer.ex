defmodule PrintClientWeb.Settings.PrinterComponent do
  use PrintClientWeb, :live_component

  alias PrintClient.Printer.Discovery
  alias PrintClient.Printer
  alias PrintClient.Label
  alias PrintClient.Settings

  require Logger

  @tabs [
    %{
      id: :network,
      title: "Network",
      icon: "hero-wifi"
    },
    %{
      id: :usb,
      title: "USB",
      icon: "hero-arrow-up-tray"
    },
    %{
      id: :serial,
      title: "Serial",
      icon: "hero-command-line-solid"
    }
  ]

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(tabs: @tabs)
      |> assign(tab: @tabs |> List.first())
      |> assign_printers(nil)
      |> assign(encodings: Label.list_encodings())
      |> assign_serial_ports()
      |> assign_usb_devices()

    {:ok, socket}
  end

  @impl true
  def update(params, socket) do
    {:ok, socket |> assign_printers(params[:printer])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ul class="list space-y-8">
      <li class="list-col">
        <.header :if={is_nil(@printer.id)}>{gettext("Create Printer")}</.header>
        <.header :if={not is_nil(@printer.id)}>{gettext("Edit Printer")}</.header>

        <.form
          :let={f}
          for={@printer_form}
          id="printer-form"
          phx-submit="update"
          phx-change="validate"
          phx-debounce="200"
          phx-target={@myself}
          class="space-y-8"
        >
          <.input
            label={gettext("Type")}
            field={f[:type]}
            type="select"
            options={Enum.map(@tabs, &{&1.title, &1.id})}
          />
          <.input
            label={gettext("Name")}
            field={f[:name]}
            type="text"
            placeholder="Enter a printer name"
          />
          <div
            :if={f[:type].value == :network}
            class="grid gap-2 grid-cols-[70%_auto] grid-rows-[auto] grid-flow-row"
          >
            <.input
              label={gettext("Hostname")}
              field={f[:hostname]}
              type="text"
              placeholder="Enter an ip or hostname"
            />
            <.input label={gettext("Port")} field={f[:port]} type="number" placeholder="9100" />
          </div>
          <div
            :if={f[:type].value == :serial}
            class="grid gap-2 grid-cols-[1fr_auto] grid-rows-[auto] grid-flow-row items-end"
          >
            <.input
              label={gettext("Serial Port")}
              field={f[:serial_port]}
              type="select"
              options={@serial_ports}
            />
            <fieldset class="fieldset mb-2 w-min">
              <label>
                <.button type="button" phx-click="refresh-serial" phx-target={@myself}>
                  <.icon name="hero-arrow-path" />
                </.button>
              </label>
            </fieldset>
          </div>
          <div :if={f[:type].value == :usb}>
            <div class="grid gap-2 grid-cols-[1fr_auto] grid-rows-[auto] grid-flow-row items-end">
              <fieldset class="fieldset mb-2">
                <label>
                  <span class="label mb-1">Select a device</span>
                  <select name="usb_device" id="usb-device-list" class="w-full select">
                    <option></option>
                    <option :for={dev <- @usb_devices} value={dev.name}>
                      {dev.name}
                    </option>
                  </select>
                </label>
              </fieldset>
              <fieldset class="fieldset mb-2 w-min">
                <label>
                  <.button type="button" phx-click="refresh-usb" phx-target={@myself}>
                    <.icon name="hero-arrow-path" />
                  </.button>
                </label>
              </fieldset>
            </div>
            <div class="grid gap-2 grid-cols-[1fr_1fr] grid-rows-[auto] grid-flow-row">
              <.input label={gettext("Vendor ID")} field={f[:vendor_id]} type="text" />
              <.input label={gettext("Product ID")} field={f[:product_id]} type="text" />
            </div>
          </div>
          <.input label={gettext("Encoding")} field={f[:encoding]} type="select" options={@encodings} />
          <div class="flex flex-row justify-baseline gap-4">
            <.link navigate={~p"/printers"} class="btn btn-neutral">Cancel</.link>
            <button type="submit" class="btn btn-success grow">Save</button>
          </div>
        </.form>
      </li>
      <li class="list-col space-y-4">
        <.header>Printers</.header>
        <div
          :if={@printers == []}
          class="flex flex-col-reverse sm:flex-row gap-4 sm:gap-8 justify-center items-center"
        >
          <h2 class="text-2xl font-bold text-content-100 opacity-50 sm:text-center">
            <p>It's pretty empty here.</p>
            <p>Try creating a new printer.</p>
          </h2>
          <img
            src={~p"/images/undraw_barbecue.svg"}
            class="hidden sm:block w-full max-w-40 grayscale brightness-150"
          />
        </div>
        <div :for={printer <- @printers} class="card w-full bg-base-100 card-sm shadow-sm">
          <div class="card-body">
            <div class="card-title">
              <h2>{printer.name}</h2>
              <span :if={printer.type == :network} class="ml-auto badge badge-primary">
                {gettext("Network")}
              </span>
              <span :if={printer.type == :serial} class="ml-auto badge badge-secondary">
                {gettext("Serial")}
              </span>
              <span :if={printer.type == :usb} class="ml-auto badge badge-accent">
                {gettext("USB")}
              </span>
            </div>
            <div :if={printer.type == :network}>
              <p>{printer.hostname}:{printer.port}</p>
            </div>
            <div :if={printer.type == :serial}>
              <p>Port: {printer.serial_port}</p>
            </div>
            <div :if={printer.type == :usb}>
              <p>Device: {printer.vendor_id}:{printer.product_id}</p>
            </div>
            <div class="card-actions ml-auto">
              <.link navigate={~p"/printers/#{printer.id}"} class="btn btn-accent">
                <.icon name="hero-pencil-square" />{gettext("Edit")}
              </.link>
              <.button
                phx-click="delete"
                phx-value-id={printer.id}
                phx-target={@myself}
                data-confirm={gettext("Are you sure you want to delete this printer?")}
              >
                <.icon name="hero-trash" />{gettext("Delete")}
              </.button>
            </div>
          </div>
        </div>
      </li>
    </ul>
    """
  end

  # --- FORM EVENTS ---

  @impl true
  def handle_event(
        "validate",
        %{"_target" => ["usb_device"], "printer" => params, "usb_device" => usb_device},
        socket
      ) do
    dev = Enum.find(socket.assigns.usb_devices, &(&1.name == usb_device))

    if is_nil(dev) do
      handle_event("validate", %{"printer" => params}, socket)
    else
      changeset =
        socket.assigns.printer
        |> Settings.change_printer(params)
        |> Ecto.Changeset.put_change(:name, dev.name)
        |> Ecto.Changeset.put_change(:vendor_id, dev.adapter_config.vendor)
        |> Ecto.Changeset.put_change(:product_id, dev.adapter_config.product)

      changeset
      |> Ecto.Changeset.apply_action(:validate)
      |> case do
        {:ok, _printer} ->
          socket
          |> assign_printers(socket.assigns.printer, changeset)

        {:error, changeset} ->
          socket
          |> assign_printers(socket.assigns.printer, changeset)
      end
      |> then(&{:noreply, &1})
    end
  end

  def handle_event("validate", %{"printer" => params}, socket) do
    socket.assigns.printer
    |> Settings.change_printer(params)
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, _printer} ->
        socket

      {:error, changeset} ->
        socket
        |> assign_printers(socket.assigns.printer, changeset)
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("update", %{"printer" => params}, socket) do
    socket.assigns.printer
    |> Settings.save_printer(params)
    |> case do
      {:ok, _printer} ->
        socket |> assign_printers(nil)

      {:error, changeset} ->
        socket
        |> assign_printers(socket.assigns.printer, changeset)
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("delete", %{"id" => printer_id}, socket) do
    printer = Settings.get_printer(printer_id)

    Settings.delete_printer(printer)
    |> case do
      {:ok, _printer} ->
        socket
        |> put_flash(:info, "Deleted printer: #{printer.name}")
        |> assign_printers(nil)

      {:error, changeset} ->
        Logger.error("SettingsLive: Failed to delete printer: #{inspect(changeset)}")

        socket
        |> put_flash(:error, "Failed to delete printer: #{printer.name}")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("refresh-serial", _params, socket), do: {:noreply, assign_serial_ports(socket)}
  def handle_event("refresh-usb", _params, socket), do: {:noreply, assign_usb_devices(socket)}

  defp assign_usb_devices(socket) do
    socket
    |> assign(usb_devices: Discovery.discover_usb_printers())
  end

  defp assign_serial_ports(socket) do
    serial_ports =
      Discovery.discover_serial_printers()
      |> Enum.map(& &1.adapter_config.port)
      |> Enum.reject(&is_nil/1)

    socket
    |> assign(serial_ports: serial_ports)
  end

  defp assign_printers(socket, printer, changeset \\ nil)

  defp assign_printers(socket, nil, changeset),
    do: assign_printers(socket, %Settings.Printer{}, changeset)

  defp assign_printers(socket, printer = %Settings.Printer{}, changeset) do
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
    |> assign(printer: printer)
    |> assign(printer_form: to_form(changeset))
  end
end
