defmodule PrintClient.Window.Print do
  alias PrintClientWeb.{Router, Endpoint, IiqSearchLive}

  use PrintClient.Window,
    window: PrintWindow,
    title: "Label Printing",
    size: {400, 483},
    fixed_size: true,
    menubar: PrintClient.MenuBar,
    icon_menu: PrintClient.Menu,
    url: fn ->
      Router.Helpers.live_url(Endpoint, IiqSearchLive)
    end
end
