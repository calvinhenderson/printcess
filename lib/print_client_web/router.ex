defmodule PrintClientWeb.Router do
  use PrintClientWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PrintClientWeb.Layouts, :root}
    # plug Desktop.Auth
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PrintClientWeb do
    pipe_through :browser

    live_session :live do
      live "/settings/printers", SettingsLive, :printers
      live "/settings/api", SettingsLive, :api
      live "/settings", SettingsLive, :preferences
      live "/", PrintLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PrintClientWeb do
  #   pipe_through :api
  # end

  # Enable <%= [@dashboard && "LiveDashboard", @mailer && "Swoosh mailbox preview"] |> Enum.filter(&(&1)) |> Enum.join(" and ") %> in development
  if Application.compile_env(:print_client, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PrintClientWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
