defmodule PrintClientWeb.TextForm do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <form phx-submit="print" class="form-control gap-2" phx-target={@myself}>
        <%# Text input %>
        <input type="text" name="text"
          onclick="this.select()"
          class="input input-bordered"
          placeholder={ gettext "Enter some text.." }
          aria-label="Label text"
          required
          />

        <div class="input-group">
          <%# Submit %>
          <button type="submit" class="btn btn-bordered grow">
            <%= gettext "Print Text" %>
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
  def handle_event("print", %{"copies" => copies, "text" => text}, socket) do
    Logger.debug("Printing to #{inspect socket.assigns.printer}")

    GenServer.cast(PrintQueue, {:push, %{
      printer: socket.assigns.printer,
      text: text,
      copies: copies
    }})

    Desktop.Window.show_notification(PrintClientWindow, "Printing text label: #{text}", timeout: 1000)

    {:noreply, socket}
  end
end
