defmodule PrintClientWeb.SettingsLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Settings

  def mount(_params, _assigns, socket) do
    printers = Settings.all_printers()
    {:ok, assign(socket,
      printers: printers,
      selected_printer: List.first(printers, %Settings.Printer{})
    )}
  end

  def handle_event("update", %{
    "id" => id,
    "name" => name,
    "hostname" => hostname,
    "port" => port,
    "primary" => primary
  }, socket) do

    port_num = with {parsed_num, _} <- Integer.parse(port) do
      parsed_num
    else
      _ -> 9100
    end

    if id == "" do
      Settings.create_printer(%{
        name: name,
        hostname: hostname,
        port: port_num,
        selected: (if primary, do: 1, else: 0)
      })
    else
      {id, _} = Integer.parse(id)
      Settings.update_printer(%Settings.Printer{id: id}, %{
        name: name,
        hostname: hostname,
        port: port_num,
        selected: (if primary, do: 1, else: 0)
      })
    end

    {:noreply, assign(socket, printers: Settings.all_printers())}
  end

  def handle_event("select", %{"printer" => printer_id}, socket) do
    {:noreply, assign(socket,
      selected_printer: Enum.find(socket.assigns.printers, %Settings.Printer{},
        fn p -> p.id == printer_id end
      )
    )}
  end
end
