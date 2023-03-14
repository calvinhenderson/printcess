import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :print_client, PrintClientWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ITW0dPmZwXnra5ZAzkNKtpmfV67q/fh0rV6eaES1UzzB3N+IOSkeJFY295dLpnRD",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
