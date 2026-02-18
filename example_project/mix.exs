defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      listeners: [Phoenix.CodeReloader],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Example.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:ecto_sql, "~> 3.12"},
      {:gettext, "~> 0.20"},
      {:json_diff_ex, "~> 0.6", override: true},
      {:live_json, "~> 0.4.5"},
      {:live_svelte, path: ".."},
      # {:live_svelte, "~> 0.17.4"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_view, "~> 1.0.9"},
      {:bandit, "~> 1.0"},
      {:ecto_sqlite3, "~> 0.17"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:wallaby, "~> 0.30", runtime: false, only: :test},
      {:phoenix_test, "~> 0.9", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev}
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
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.js": ["cmd --cd assets node build.js"],
      "test.e2e": ["assets.js", "ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing"],
      "assets.build": ["tailwind default"],
      "assets.deploy": [
        "tailwind default --minify",
        "cmd --cd assets node build.js --deploy",
        "phx.digest"
      ]
    ]
  end
end
