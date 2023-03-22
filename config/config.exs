# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Pass the env through
config :print_client, env: Mix.env()

# Configures the endpoint
config :print_client, PrintClientWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 0],
  url: [host: "localhost"],
  render_errors: [view: PrintClientWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PrintClient.PubSub,
  live_view: [signing_salt: "O0X5LNCX"],
  server: true

# Configure repo
config :print_client,
  ecto_repos: [PrintClient.Repo]

# config :print_client, PrintClient.Repo

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind, version: "3.2.7", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
  cd: Path.expand("../assets", __DIR__)
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
