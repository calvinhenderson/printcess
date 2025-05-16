defmodule PrintClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  # User's Config directory
  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "exprint"])
  end

  @impl true
  def start(_type, _args) do
    Desktop.identify_default_locale(PrintClientWeb.Gettext)
    File.mkdir_p!(config_dir())

    Logger.info("Saving settings to path: #{config_dir()}")

    # Update the repo to point to our actual database
    Application.put_env(:print_client, PrintClient.Repo,
      database: Path.join(config_dir(), "/settings.db")
    )

    children = [
      # Start the Telemetry supervisor
      PrintClientWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: PrintClient.PubSub},

      # Start the printer registry
      {Registry, name: PrintClient.Printer.Registry, keys: :unique},

      # Start the automatic clustering supervisor
      {Cluster.Supervisor, [topologies(), [name: PrintClient.ClusterSupervisor]]},

      # Start the Unix Socket API
      # {PrintClient.UnixSocketApi, name: UnixSocket},

      # Start the Repo
      PrintClient.Repo,

      # One-off post-startup tasks
      PrintClient.StartupTasks,

      # Start the Endpoint (http/https)
      PrintClientWeb.Endpoint,
      PrintClient.Printer.Supervisor,

      # Start the printer queue
      # {PrintClient.Printer.Queue, name: PrintQueue},
      PrintClient.Window.Print
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

  defp topologies,
    do: [background_job: [strategy: Cluster.Strategy.Gossip]]
end
