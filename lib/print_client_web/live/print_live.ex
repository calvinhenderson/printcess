defmodule PrintClientWeb.PrintLive do
  alias PrintClient.Settings
  use PrintClientWeb, :live_view

  alias PrintClient.Printer
  alias PrintClient.Printer.Adapter

  require Logger

  def print(printer_id, template_name, params, copies)
      when is_integer(copies) and copies > 0 do
    Logger.info("PrintLive: printing to Printer.Device #{printer_id}, copies: #{copies}")
    Logger.debug("PrintLive: Template #{template_name} contents: #{inspect(params)}")

    # TODO: Render the template with the given params.
    _ = template_name
    _ = params
    data = nil

    Printer.add_job(printer_id, data)
  end

  def print(_, _, _), do: nil

  def list_printers, do: Printer.Discovery.discover_all_printers() |> dbg()

  def list_templates do
    [
      %{
        name: "Combined Chromebook Label",
        template: """
          <h1>Combined Chromebook Label</h1>
          <p>Asset: {{ asset_number }}</p>
          <p>Serial: {{ serial_number }}</p>
          <p>Owner: {{ username }}</p>
        """
      }
    ]
  end

  defp get_printer_config(printer_id),
    do: Enum.find(list_printers(), &(&1.printer_id == printer_id))

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> assign(:changeset, nil)
      |> assign(:printers, list_printers())
      |> assign(:selected_printer, nil)
      |> assign(:templates, list_templates())
      |> assign(:template, nil)
      |> assign(:template_params, %{})

    {:ok, socket}
  end
end
