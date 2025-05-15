defmodule PrintClient.Window.Print do
  use PrintClientWeb, :verified_routes

  use PrintClient.Window,
    window: PrintWindow,
    title: "Print Client",
    menubar: PrintClient.MenuBar,
    icon_menu: PrintClient.Menu,
    url: ~p"/"
end
