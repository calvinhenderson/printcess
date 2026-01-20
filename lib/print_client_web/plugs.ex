defmodule PrintClientWeb.Plugs do
  import Plug.Conn

  def assign_current_scope(conn, _) do
    path =
      conn
      |> Plug.Conn.request_url()
      |> URI.parse()
      |> then(& &1.path)

    assign(conn, :current_scope, %{
      path: path
    })
  end
end
