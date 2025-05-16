defmodule PrintClient.MixProject do
  use Mix.Project

  @app :print_client

  def project do
    [
      app: @app,
      version: "1.1.0",
      elixir: "~> 1.16.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PrintClient.Application, []},
      extra_applications: [:logger, :runtime_tools, :observer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      # {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.18.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},

      # Desktop application dependencies
      {:desktop, "~> 1.5"},

      # Serial printer connections
      {:circuits_uart, "~> 1.5"},
      # Usb printer connections
      {:usb, "~> 0.2.1"},
      {:csv, "~> 3.2"},

      # Label generation
      {:mustache, "~> 0.5.0"},
      {:mogrify, "~> 0.9.3"},
      {:qr_code, "~> 3.2.0"},

      # Clustering
      {:libcluster, "~> 3.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      env: ["export EXQLITE_SYSTEM_CFLAGS=-mmacosx-version-min=12.1"],
      setup: ["deps.get", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "esbuild.install --if-missing",
        "tailwind.install --if-missing"
      ],
      "assets.build": [
        "esbuild print_client",
        "tailwind print_client"
      ],
      "assets.deploy": [
        "esbuild print_client --minify",
        "tailwind print_client --minify",
        "phx.digest"
      ]
    ]
  end

  ## Releases

  defp releases do
    [
      app: [
        applications: [runtime_tools: :permanent, ssl: :permanent],
        overwrite: true,
        cookie: "#{@app}_cookie",
        quiet: true,
        strip_beams: Mix.env() == :prod
      ]
    ]
  end
end
