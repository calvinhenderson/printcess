defmodule PrintClientWeb.AssetPrintController do
  use PrintClientWeb, :controller

  alias PrintClient.Settings

  require Logger

  def index(conn, _params) do
    conn
    |> assign(:strip_leading, "")
    |> render("index.html")
  end

  def print(conn, %{"asset" => asset, "serial" => serial, "strip_leading" => strip_leading}) do
    if not Regex.match?(~r/^[0-9]+$/, asset) do
      Desktop.Window.show_notification(
        PrintClientWindow,
        "Asset number \"#{asset}\" may be malformed",
        timeout: 5000
      )
    end

    if not Regex.match?(~r/^[A-z0-9]+$/, serial) do
      Desktop.Window.show_notification(
        PrintClientWindow,
        "Serial number \"#{serial}\" may be malformed",
        timeout: 5000
      )
    end

    serial = String.upcase(serial, :ascii)

    serial =
      if String.length(strip_leading) > 0 do
        serial |> String.trim_leading(strip_leading)
      end

    Logger.debug("[AssetForm] submitting asset label #{asset}, #{serial}")

    printer =
      Enum.find(
        Settings.all_printers(),
        fn p -> p.selected != 0 end
      )

    GenServer.cast(
      PrintQueue,
      {:push,
       %{
         printer: printer,
         asset: asset,
         serial: serial,
         copies: 1
       }}
    )

    Desktop.Window.show_notification(
      PrintClientWindow,
      "Printing asset label: #{asset},#{serial}",
      timeout: 1000
    )

    conn
    |> assign(:strip_leading, strip_leading)
    |> render("index.html")
  end
end
