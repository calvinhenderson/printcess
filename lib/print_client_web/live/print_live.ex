defmodule PrintClientWeb.PrintLive do
  defmodule QueryForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :query, :string
    end

    def changeset(query, attrs \\ %{}), do: cast(query, attrs, [:query])
  end

  defmodule AssetForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :username, :string
      field :asset, :string
      field :serial, :string
      field :copies, :integer, default: 1
    end

    def changeset(asset, attrs \\ %{}, required \\ [:username, :asset, :serial, :copies]) do
      asset
      |> cast(attrs, [:username, :asset, :serial, :copies])
      |> validate_required(required)
      |> validate_number(:copies, min: 1)
    end
  end

  use PrintClientWeb, :live_view

  alias PrintClient.Printer
  alias PrintClient.Label
  alias __MODULE__.AssetForm
  import PrintClientWeb.PrintComponents

  require Logger

  def print(%Printer{} = printer, %Label.Template{} = template, params) do
    Logger.info(
      "PrintLive: printing #{template.name} to #{printer.printer_id} with params #{inspect(params)}"
    )

    data = Label.render(template, params)

    Printer.add_job(printer.printer_id, data)
  end

  def print(printer, template, params), do: dbg([printer, template, params])

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> assign_changes()
      |> assign_query()
      |> assign(selected_printer: nil)
      |> assign(selected_template: nil)

    {:ok, socket}
  end

  @impl true
  def handle_info({:select_printer, printer}, socket) do
    # Tell the current printer to stop.
    if is_struct(socket.assigns.selected_printer, Printer) do
      Printer.Supervisor.stop_printer(socket.assigns.selected_printer.printer_id)
    end

    case printer do
      %Printer{printer_id: _} = printer ->
        Printer.Supervisor.start_printer(printer)

      _ ->
        nil
    end

    {:noreply, socket |> assign(:selected_printer, printer)}
  end

  def handle_info({:select_template, template}, socket),
    do: {:noreply, socket |> assign(:selected_template, template)}

  @impl true
  def handle_event(
        "print",
        params,
        %{assigns: %{selected_printer: printer, selected_template: template}} = socket
      ) do
    Logger.debug("PrintLive: got printing params #{inspect(params)}")

    print(printer, template, params)

    {:noreply,
     socket
     |> assign_changes(params)}
  end

  @impl true
  def handle_event("print", _params, socket), do: {:noreply, socket}

  defp assign_query(socket, query \\ %{}) do
    changeset = QueryForm.changeset(%QueryForm{}, query)
    assign(socket, :query, %{changeset | action: :insert})
  end

  defp assign_changes(socket, changes \\ %{}) do
    changeset = AssetForm.changeset(%AssetForm{}, changes)
    assign(socket, :changeset, %{changeset | action: :insert})
  end
end
