defmodule PrintClientWeb.AssetForm do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
      <form phx-submit="print" phx-target={@myself} class="form-control gap-2">
        <div class="input-group md:input-group-vertical">
          <%# Asset number input %>
          <input type="text" name="asset"
            onclick="this.select()"
            class="input input-bordered w-24 md:w-max grow"
            placeholder={ gettext "Asset number.." }
            aria-label="Asset number"
            required
            />

          <%# Serial number input %>
          <input type="text" name="serial"
            onclick="this.select()"
            class="input input-bordered w-36 md:w-max grow"
            placeholder={ gettext "Serial number.." }
            aria-label="Serial number"
            autocapitalize="characters"
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
            class="input input-bordered w-24 tooltip tooltip-bottom"
            value="1" aria-label="Number of copies"
            required
            />
        </div>
      </form>
    """
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

    {:noreply, socket}
  end
end
