defmodule PrintClientWeb.TextForm do
  use PrintClientWeb, :live_component

  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, copies: "1", text: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      phx-submit="print"
      phx-change="update"
      class="form-control gap-2 w-full px-2"
      phx-target={@myself}
    >
      <%!-- Text input --%>
      <input
        type="text"
        name="text"
        phx-debounce="250"
        onclick="this.select()"
        class="input input-bordered"
        placeholder={gettext("Enter some text..")}
        aria-label="Label text"
        value={@text}
        required
      />

      <div class="input-group w-full">
        <%!-- Submit --%>
        <button type="submit" class="btn btn-bordered grow">
          {gettext("Print Text")}
        </button>

        <%!-- Num. copies --%>
        <input
          type="number"
          name="copies"
          phx-debounce="250"
          class="input input-bordered w-20 tooltip tooltip-bottom"
          value={@copies}
          aria-label="Number of copies"
          required
        />
      </div>
    </form>
    """
  end

  @impl true
  def handle_event("update", %{"copies" => copies, "text" => text}, socket) do
    {:noreply, assign(socket, copies: copies, text: text)}
  end

  @impl true
  def handle_event("print", %{"copies" => copies, "text" => text}, socket) do
    Logger.debug("Printing to #{inspect(socket.assigns.printer)}")

    GenServer.cast(
      PrintQueue,
      {:push,
       %{
         printer: socket.assigns.printer,
         text: text,
         copies: copies
       }}
    )

    Desktop.Window.show_notification(PrintClientWindow, "Printing text label: #{text}",
      timeout: 1000
    )

    {:noreply, assign(socket, copies: copies, text: nil)}
  end
end
