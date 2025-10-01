defmodule PrintClientWeb.LiveHooks do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4]

  def on_mount(:current_scope, _params, _session, socket) do
    socket =
      attach_hook(socket, :assign_current_scope, :handle_params, &assign_current_scope/3)

    {:cont, socket}
  end

  defp assign_current_scope(_params, uri, socket) do
    uri = URI.parse(uri)

    {:cont,
     assign(socket, :current_scope, %{
       path: uri.path
     })}
  end
end
