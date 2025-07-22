defmodule PrintClient.Window.BulkAssetPrint do
  alias PrintClientWeb.{Router, Endpoint}

  use PrintClient.Window,
    window: BulkAssetPrintWindow,
    title: "Bulk Assets",
    size: {400, 380},
    fixed_size: true,
    url: fn ->
      Router.Helpers.asset_print_url(Endpoint, :index)
    end
end
