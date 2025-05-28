defmodule PrintClientWeb.PrintLive do
  use PrintClientWeb, :live_view

  alias PrintClientWeb.PrintForm
  alias PrintClientWeb.Forms.{OptionsForm}
  alias PrintClient.{Printer, Label}
  alias PrintClient.Printer.Discovery
  import PrintClientWeb.PrintComponents

  require Logger

  # Handle multiple printers
  def print(printers, template, params) when is_list(printers) do
    Enum.map(printers, fn printer ->
      print(printer, template, params)
    end)
  end

  # Print to a single printer
  def print(%Printer{} = printer, %Label.Template{} = template, params) do
    Logger.info(
      "PrintLive: printing #{template.name} to #{printer.printer_id} with params #{inspect(params)}"
    )

    with %{} = validated when map_size(validated) > 0 <- params,
         rendered <- Label.render(template, validated),
         {:ok, data} <- Label.encode(:tspl, rendered, copies: validated.copies) do
      Printer.add_job(printer.printer_id, data)
    else
      {:error, reason} ->
        Logger.error("PrintLive: failed to render template #{inspect(reason)}")
    end
  end

  def print(printer, template, params), do: dbg([printer, template, params])

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(print_params: %{})
      |> assign(selected_printers: [])
      |> assign(selected_template: nil)
      |> assign_options()

    if connected?(socket),
      do: Discovery.subscribe()

    {:ok, socket}
  end

  @impl true
  def handle_info({:select_printer, printer}, socket) do
    # Tell the current printer to stop.
    socket =
      case printer do
        %Printer{printer_id: _} = printer ->
          Printer.Supervisor.start_printer(printer)

          printers =
            [printer | socket.assigns.selected_printers]
            |> Enum.reduce([], fn printer, acc ->
              if Enum.find(acc, &(&1.printer_id == printer.printer_id)) do
                acc
              else
                Printer.subscribe(printer)
                [printer | acc]
              end
            end)

          socket
          |> assign(selected_printers: printers)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_info({:added, %Printer{} = _printer}, socket) do
    {:noreply, socket}
  end

  def handle_info({:removed, %Printer{} = printer}, socket) do
    socket =
      socket
      |> assign(
        printers: Enum.reject(socket.assigns.printers, &(&1.printer_id == printer.printer_id))
      )

    {:noreply, socket}
  end

  def handle_info({:select_template, template}, socket),
    do: {:noreply, socket |> assign(:selected_template, template)}

  def handle_info({:print, params}, socket) do
    with printers when printers != [] <- Map.get(socket.assigns, :selected_printers, []),
         %Label.Template{} = template <- Map.get(socket.assigns, :selected_template) do
      print(printers, template, params)
      |> Enum.reduce(socket, fn result, socket ->
        case result do
          {:ok, _job_id} ->
            socket

          {:error, reason} ->
            socket |> put_flash(:error, "job failed: #{inspect(reason)}")
        end
      end)
    else
      reason ->
        dbg(reason)

        socket
        |> put_flash(:error, "Select a printer and a template first.")
    end
    |> then(&{:noreply, &1})
  end

  def handle_info({:changed, params}, socket),
    do: {:noreply, assign(socket, :print_params, params)}

  def handle_info({type, message}, socket) when type in [:info, :error],
    do: {:noreply, socket |> put_flash(type, message)}

  @impl true
  def handle_event("clear-printer", %{"id" => printer_id}, socket) do
    # Stop the printer service
    Printer.Supervisor.stop_printer(printer_id)

    Printer.unsubscribe(%{printer_id: printer_id})

    # Remove it from the selected list
    printers =
      socket.assigns.selected_printers
      |> Enum.reject(&(&1.printer_id == printer_id))

    {:noreply, socket |> assign(selected_printers: printers)}
  end

  def handle_event("clear-template", _params, socket) do
    send(self(), {:select_template, nil})
    {:noreply, socket}
  end

  def handle_event("options", params, socket),
    do: {:noreply, socket |> assign_options(params)}

  defp assign_options(socket, params \\ %{}) do
    changeset = OptionsForm.changeset(%OptionsForm{}, params)

    socket
    |> assign(options: %{changeset | action: :validate})
  end
end
