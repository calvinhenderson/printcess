defmodule PrintClientWeb.SettingsLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  require Logger

  def mount(_params, _assigns, socket) do
    printers = Settings.all_printers()

    tab_form = to_form(%{"selected" => "printers"})

    socket =
      socket
      |> assign(printers: printers)
      |> assign(selected_printer: List.first(printers, %Settings.Printer{}))
      |> assign(tab: tab_form)
      |> assign_settings()

    {:ok, socket}
  end

  def handle_event("show-tab", %{"selected" => tab}, socket) do
    form = to_form(%{"selected" => tab})
    {:noreply, socket |> assign(tab: form)}
  end

  def handle_event("update-printer", attrs, socket) do
    port =
      with {port_num, _} <- Integer.parse(attrs["port"]) do
        port_num
      else
        _ -> 9100
      end

    changeset = %{
      name: if(attrs["name"], do: attrs["name"], else: attrs["hostname"]),
      hostname: attrs["hostname"],
      port: port,
      selected: if(attrs["primary"], do: 1, else: 0)
    }

    {:ok, printer} =
      if !Map.has_key?(attrs, "printer_id") or attrs["printer_id"] == "" do
        Settings.create_printer(changeset)
      else
        {printer_id, _} = Integer.parse(attrs["printer_id"])
        Settings.update_printer(%Settings.Printer{id: printer_id}, changeset)
      end

    {:noreply,
     assign(socket,
       printers: Settings.all_printers(),
       selected_printer: printer
     )}
  end

  def handle_event("select", %{"printer_id" => printer_id}, socket) do
    printers = Settings.all_printers()

    with {printer_id_num, _} <- Integer.parse(printer_id) do
      selected = Enum.find(printers, %Settings.Printer{}, fn p -> p.id == printer_id_num end)

      Logger.debug("#{inspect(printers)}, (#{inspect(printer_id)}): #{inspect(selected)}")

      {:noreply,
       assign(socket,
         printers: printers,
         selected_printer: selected
       )}
    else
      _ ->
        {:noreply,
         assign(socket,
           printers: printers,
           selected_printer: %Settings.Printer{}
         )}
    end
  end

  def handle_event("select", _, socket), do: {:noreply, socket}

  def handle_event("delete", _params, socket) do
    {:ok, printer} = Settings.delete_printer(socket.assigns.selected_printer)
    printers = Enum.filter(socket.assigns.printers, fn p -> p.id != printer.id end)
    Logger.debug("deleted (#{printer.id}): #{inspect(printers)}")

    {:noreply,
     assign(socket,
       printers: printers,
       selected_printer: %Settings.Printer{}
     )}
  end

  defp assign_settings(socket) do
    socket
    |> assign(settings_form: to_form(Settings.change_settings()))
  end
end
