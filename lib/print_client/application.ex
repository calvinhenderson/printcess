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

      # Start the Repo
      PrintClient.Repo,

      { Desktop.Window,
        [
          app: :print_client,
          id: PrintClientWindow,
          title: "Print Client",
          size: @window_size,
          min_size: @window_size,
          max_size: @window_size,
          icon: "icon.png",
          menubar: PrintClient.MenuBar,
          icon_menu: PrintClient.Menu,
          url: &PrintClientWeb.Endpoint.url/0
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PrintClient.Supervisor]
    ret = Supervisor.start_link(children, opts)

    # Perform db initialization tasks
    PrintClient.Repo.initialize()

    :wx.set_env(Desktop.Env.wx_env())
    frame = Desktop.Window.frame(PrintClientWindow)
    :wxWindow.setMaxSize(frame, @window_size)

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
