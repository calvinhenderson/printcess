defmodule PrintClientWeb.AssetPrintController do
  use PrintClientWeb, :controller

  alias PrintClient.Settings
  alias PrintClientWeb.AssetForm

  def index(conn, _params) do
    conn
    |> render("index.html", [])
  end

  def print(conn, params) do
    assigns = %{
      printer: Enum.find(Settings.all_printers(),
          fn p -> p.selected != 0 end)
    }
    AssetForm.handle_event("print", Map.merge(params, %{"copies" => 1}), %{assigns: assigns})

    conn
    |> redirect(to: "/asset-spam")
  end
end
