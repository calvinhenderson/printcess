defmodule PrintClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @window_size {400, 360}

  # User's Config directory
  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "exprint"])
  end

  @impl true
  def start(_type, _args) do
    Desktop.identify_default_locale(PrintClientWeb.Gettext)
    File.mkdir_p!(config_dir())

    Logger.info("Saving settings to path: #{config_dir()}")
    Application.put_env(:print_client, PrintClient.Repo,
      database: Path.join(config_dir(), "/settings.db")
    )

    children = [
      # Start the Telemetry supervisor
      PrintClientWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: PrintClient.PubSub},
      # Start the Endpoint (http/https)
      PrintClientWeb.Endpoint,
      # Start a worker by calling: PrintClient.Worker.start_link(arg)
      # {PrintClient.Worker, arg}

      { Desktop.Window,
        [
          app: :print_client,
          id: PrintClientWindow,
          title: "Print Client",
          size: @window_size,
          icon: "icon.png",
          menubar: PrintClient.MenuBar,
          icon_menu: PrintClient.Menu,
          url: &PrintClientWeb.Endpoint.url/0
        ]
      },

      # Start the Repo
      PrintClient.Repo,

      # One-off post-startup tasks
      { PrintClient.StartupTasks,
        [
          window_size: @window_size
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PrintClient.Supervisor]
    ret = Supervisor.start_link(children, opts)

    ret
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PrintClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
