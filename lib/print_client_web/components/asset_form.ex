defmodule PrintClientWeb.AssetForm do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, copies: "1", asset: "", serial: "")}
  end
 
  @impl true
  def render(assigns) do
    ~H"""
      <form phx-submit="print" phx-change="update" phx-target={@myself} class="form-control gap-2 w-full px-2">
        <div class="input-group md:input-group-vertical w-full">
          <%# Asset number input %>
          <input type="text" name="asset"
            phx-debounce="250"
            onclick="this.select()"
            class="input input-bordered w-full"
            placeholder={ gettext "Asset number.." }
            aria-label="Asset number"
            value={@asset}
            required
            />

          <%# Serial number input %>
          <input type="text" name="serial"
            phx-debounce="250"
            onclick="this.select()"
            class="input input-bordered w-full"
            placeholder={ gettext "Serial number.." }
            aria-label="Serial number"
            autocapitalize="characters"
            value={@serial}
            required
            />
        </div>

        <div class="input-group">
          <%# Submit %>
          <button type="submit" class="btn btn-bordered grow">
            <%= gettext "Print Asset" %>
          </button>

          <%# Num. copies %>
          <input type="number" name="copies"
            phx-debounce="250"
            class="input input-bordered w-20 tooltip tooltip-bottom"
            value={@copies} aria-label="Number of copies"
            required
            />
        </div>
      </form>
    """
  end

  @impl true
  def handle_event("update", %{"copies" => copies, "asset" => asset, "serial" => serial}, socket) do
    {:noreply, assign(socket, copies: copies, asset: asset, serial: serial)}
  end

  @impl true
  def handle_event("print", %{"copies" => copies, "asset" => asset, "serial" => serial}, socket) do
    if not Regex.match?(~r/^[0-9]+$/, asset) do
      Desktop.Window.show_notification(PrintClientWindow, "Asset number \"#{asset}\" may be malformed", timeout: 5000)
    end

    if not Regex.match?(~r/^[A-z0-9]+$/, serial) do
      Desktop.Window.show_notification(PrintClientWindow, "Serial number \"#{serial}\" may be malformed", timeout: 5000)
    end

    serial = String.upcase(serial, :ascii)

    Logger.debug("[AssetForm] submitting asset label #{asset}, #{serial}")

    GenServer.cast(PrintQueue, {:push, %{
      printer: socket.assigns.printer,
      asset: asset,
      serial: serial,
      copies: copies,
    }})

    Desktop.Window.show_notification(PrintClientWindow, "Printing asset label: #{asset},#{serial}", timeout: 1000)

    {:noreply, assign(socket, copies: copies, asset: nil, serial: nil)}
  end
end
