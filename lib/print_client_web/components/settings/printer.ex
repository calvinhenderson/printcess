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
    <div class="max-w-[1600px] mx-auto pb-20">
      <div class="mb-8 border-b border-base-200 pb-6">
        <h1 class="text-3xl font-bold text-base-content">Printers</h1>
        <p class="text-base-content/60 mt-2">Manage physical and network printing devices.</p>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
        <div class="xl:col-span-5 xl:sticky xl:top-6">
          <div class="card bg-base-100 shadow-sm border border-base-200">
            <div class="card-body">
              <div class="flex items-center gap-2 mb-4 pb-4 border-b border-base-100">
                <div class="p-2 bg-primary/10 text-primary rounded-lg">
                  <.icon name="hero-printer" class="w-5 h-5" />
                </div>
                <h2 class="font-bold text-lg">
                  {if is_nil(@printer.id),
                    do: gettext("Add New Printer"),
                    else: gettext("Edit Configuration")}
                </h2>
              </div>

              <.form
                :let={f}
                for={@printer_form}
                id="printer-form"
                phx-submit="update"
                phx-change="validate"
                phx-debounce="200"
                phx-target={@myself}
                class="flex flex-col gap-5"
              >
                <.input
                  field={f[:name]}
                  label="Printer Name"
                  type="text"
                  placeholder="e.g. Front Desk Label Printer"
                />

                <.input
                  field={f[:type]}
                  label="Connection Type"
                  type="select"
                  options={Enum.map(@tabs, &{&1.title, &1.id})}
                  class="select select-bordered w-full font-medium"
                />

                <div
                  :if={f[:type].value == :network}
                  class="grid grid-cols-5 bg-base-200/30 gap-4 p-4 rounded-xl border border-base-200"
                >
                  <div class="col-span-3 w-full">
                    <.input
                      label={gettext("Hostname / IP")}
                      field={f[:hostname]}
                      type="text"
                      placeholder="192.168.1.x"
                      class="input font-mono text-sm"
                    />
                  </div>
                  <div class="col-span-2">
                    <.input
                      label={gettext("Port")}
                      field={f[:port]}
                      type="number"
                      placeholder="9100"
                      class="input font-mono text-sm"
                    />
                  </div>
                </div>

                <div
                  :if={f[:type].value == :serial}
                  class="bg-base-200/30 p-4 rounded-xl border border-base-200"
                >
                  <label class="label">
                    <span class="label-text">{gettext("Serial Port")}</span>
                  </label>
                  <div class="join w-full">
                    <select
                      id={f[:serial_port].id}
                      name={f[:serial_port].name}
                      class="select select-bordered join-item w-full"
                    >
                      <option value="">-- Choose Device --</option>
                      <option :for={port <- @serial_ports} value={port}>{port}</option>
                    </select>
                    <button
                      type="button"
                      phx-click="refresh-serial"
                      phx-target={@myself}
                      class="btn join-item btn-square border-base-300"
                    >
                      <.icon name="hero-arrow-path" class="w-5 h-5" />
                    </button>
                  </div>
                </div>

                <div
                  :if={f[:type].value == :usb}
                  class="flex flex-col gap-4 bg-base-200/30 p-4 rounded-xl border border-base-200"
                >
                  <div>
                    <label class="label">
                      <span class="label-text">{gettext("Select Device")}</span>
                    </label>
                    <div class="join w-full">
                      <select
                        name="usb_device"
                        id="usb-device-list"
                        class="select select-bordered join-item w-full"
                      >
                        <option value="">-- Choose Device --</option>
                        <option :for={dev <- @usb_devices} value={dev.name}>{dev.name}</option>
                      </select>
                      <button
                        type="button"
                        phx-click="refresh-usb"
                        phx-target={@myself}
                        class="btn join-item btn-square border-base-300"
                      >
                        <.icon name="hero-arrow-path" class="w-5 h-5" />
                      </button>
                    </div>
                  </div>

                  <div class="grid grid-cols-2 gap-4">
                    <.input
                      label={gettext("Vendor ID")}
                      field={f[:vendor_id]}
                      type="text"
                      class="input font-mono text-sm"
                    />
                    <.input
                      label={gettext("Product ID")}
                      field={f[:product_id]}
                      type="text"
                      class="input font-mono text-sm"
                    />
                  </div>
                </div>

                <div class="pt-2 border-t border-base-100 mt-2">
                  <.input
                    label={gettext("Driver / Encoding")}
                    field={f[:encoding]}
                    type="select"
                    options={@encodings}
                  />
                </div>

                <div class="flex items-center gap-3 pt-4">
                  <.link navigate={~p"/printers"} class="btn btn-ghost flex-1">
                    Cancel
                  </.link>
                  <button type="submit" class="btn btn-primary flex-1 shadow-lg shadow-primary/20">
                    {if is_nil(@printer.id), do: "Create Printer", else: "Save Changes"}
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <div class="xl:col-span-7 flex flex-col gap-6">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold flex items-center gap-2">
              <.icon name="hero-server-stack" class="w-6 h-6 text-base-content/70" /> Active Printers
              <span class="badge badge-sm badge-ghost font-normal text-xs">
                {length(@printers)} Devices
              </span>
            </h2>
          </div>

          <div
            :if={@printers == []}
            class="flex flex-col items-center justify-center py-16 bg-base-100 rounded-box border border-dashed border-base-300 text-center"
          >
            <div class="bg-base-200 rounded-full p-6 mb-4 opacity-50">
              <.icon name="hero-printer" class="w-12 h-12" />
            </div>
            <h3 class="font-bold text-lg">No printers found</h3>
            <p class="text-base-content/60 max-w-xs mx-auto">
              Use the form on the left to add your first network or local printer.
            </p>
          </div>

          <div class="grid grid-cols-1 gap-4">
            <div
              :for={printer <- @printers}
              class="card bg-base-100 shadow-sm border border-base-200 group transition-all hover:shadow-md hover:border-primary/40"
            >
              <div class="card-body p-6 flex-row gap-6 items-center w-full">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-3 mb-1">
                    <h3 class="font-bold text-lg truncate" title={printer.name}>{printer.name}</h3>
                    <span class={[
                      "badge badge-sm border-0 font-medium",
                      printer.type == :network && "bg-blue-100 text-blue-700",
                      printer.type == :serial && "bg-purple-100 text-purple-700",
                      printer.type == :usb && "bg-orange-100 text-orange-700"
                    ]}>
                      {printer.type |> to_string() |> String.upcase()}
                    </span>
                  </div>

                  <div class="text-xs font-mono text-base-content/60 flex flex-wrap gap-x-4 gap-y-1">
                    <span :if={printer.type == :network} class="flex items-center gap-1">
                      <.icon name="hero-globe-alt" class="w-3 h-3" />
                      {printer.hostname}:{printer.port}
                    </span>
                    <span :if={printer.type == :serial} class="flex items-center gap-1">
                      <.icon name="hero-cpu-chip" class="w-3 h-3" />
                      {printer.serial_port}
                    </span>
                    <span :if={printer.type == :usb} class="flex items-center gap-1">
                      <.icon name="hero-bolt" class="w-3 h-3" /> PID: {printer.product_id}
                    </span>
                    <span class="flex items-center gap-1 opacity-50">
                      &bull; {printer.encoding}
                    </span>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <.link
                    navigate={~p"/printers/#{printer.id}"}
                    class="btn btn-sm btn-square btn-ghost tooltip"
                    data-tip="Edit"
                  >
                    <.icon name="hero-pencil-square" class="w-5 h-5" />
                  </.link>
                  <.button
                    phx-click="delete"
                    phx-value-id={printer.id}
                    phx-target={@myself}
                    data-confirm={gettext("Are you sure you want to delete this printer?")}
                    class="btn btn-sm btn-square btn-ghost text-error hover:bg-error/10 tooltip"
                    data-tip="Delete"
                  >
                    <.icon name="hero-trash" class="w-5 h-5" />
                  </.button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
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

  defp assign_printers(socket, %Settings.Printer{} = printer, changeset) do
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
