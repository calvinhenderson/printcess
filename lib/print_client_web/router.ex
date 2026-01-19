defmodule PrintClientWeb.Router do
  use PrintClientWeb, :router

  import PrintClientWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PrintClientWeb.Layouts, :root}
    # plug Desktop.Auth
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_scope
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PrintClientWeb do
    pipe_through :browser

    live_session :live, on_mount: [{PrintClientWeb.LiveHooks, :current_scope}] do
      # Printing Views
      live "/views", ViewLive.Index, :index
      live "/views/new", ViewLive.Form, :new
      live "/views/:id", ViewLive.Show, :show
      live "/views/:id/edit", ViewLive.Form, :edit

      # Print Jobs
      live "/jobs", JobsLive

      # Settings
      live "/printers", PrintersLive, :show
      live "/printers/:id", PrintersLive, :edit
      live "/templates", TemplatesLive, :show
      live "/templates/new", TemplatesLive, :new
      live "/templates/:id", TemplatesLive, :edit
      live "/settings/api", SettingsLive, :api
      live "/settings", SettingsLive, :preferences

      # Dashboard
      live "/", DashboardLive
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
