defmodule PrintClient.Window.Settings do
  alias PrintClientWeb.{Router, Endpoint, SettingsLive}

  use PrintClient.Window,
    window: SettingsWindow,
    title: "Settings",
    size: {400, 380},
    fixed_size: true,
    url: fn ->
      Router.Helpers.live_url(Endpoint, SettingsLive)
    end
end
