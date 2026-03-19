defmodule LiveSvelte.MixProject do
  use Mix.Project

  @version "0.18.0"
  @repo_url "https://github.com/woutdp/live_svelte"

  def project do
    [
      app: :live_svelte,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],

      # Hex
      description: "E2E reactivity for Svelte and LiveView",
      package: package(),

      # Docs
      name: "LiveSvelte",
      docs: [
        name: "LiveSvelte",
        source_ref: "v#{@version}",
        source_url: @repo_url,
        homepage_url: @repo_url,
        main: "readme",
        logo: "logo_3.png",
        links: %{
          "GitHub" => @repo_url,
          "Sponsor" => "https://github.com/sponsors/woutdp"
        },
        extras: [
          "README.md": [title: "LiveSvelte"],

          # Getting Started
          "guides/installation.md": [title: "Installation"],
          "guides/upgrade_guide.md": [title: "Upgrade Guide"],
          "guides/basic_usage.md": [title: "Basic Usage"],

          # Core Usage
          "guides/forms.md": [title: "Forms and Validation"],
          "guides/uploads.md": [title: "File Uploads"],
          "guides/streams.md": [title: "Phoenix Streams"],
          "guides/ssr.md": [title: "Server-Side Rendering"],
          "guides/configuration.md": [title: "Configuration"],

          # Reference
          "guides/api_reference.md": [title: "API Reference"],

          # Advanced Topics
          "guides/introduction.md": [title: "Introduction"],
          "guides/testing.md": [title: "Testing"],
          "guides/deployment.md": [title: "Deployment"],

          # Help & Troubleshooting
          "guides/troubleshooting.md": [title: "Troubleshooting"]
        ],
        groups_for_extras: [
          "Getting Started": ~r/guides\/(installation|upgrade_guide|basic_usage)/,
          "Core Usage": ~r/guides\/(forms|uploads|streams|ssr|configuration)/,
          Reference: ~r/guides\/api_reference/,
          "Advanced Topics": ~r/guides\/(introduction|testing|deployment)/,
          "Help & Troubleshooting": ~r/guides\/troubleshooting/
        ]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp package() do
    [
      maintainers: ["Wout De Puysseleir"],
      licenses: ["MIT"],
      links: %{
        Changelog: @repo_url <> "/blob/master/CHANGELOG.md",
        GitHub: @repo_url
      },
      files:
        ~w(assets/copy/tsconfig.json assets/js guides lib mix.exs package.json .formatter.exs LICENSE.md README.md CHANGELOG.md)
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:makeup_html, "~> 0.1.0", only: :dev, runtime: false},
      {:easy_publish, "~> 0.1", only: [:dev], runtime: false},
      {:igniter, "~> 0.6", optional: true},
      {:phoenix_vite, "~> 0.4"},
      {:jsonpatch, "~> 2.3"},
      {:ecto, ">= 3.0.0", optional: true},
      {:phoenix_ecto, ">= 4.0.0", optional: true},
      {:jason, "~> 1.2", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:nodejs, "~> 3.1"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:phoenix, ">= 1.7.0"},
      {:phoenix_html, ">= 3.3.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp aliases do
    [
      "release.patch": ["easy_publish.release patch --branch=master"],
      "release.minor": ["easy_publish.release minor --branch=master"],
      "release.major": ["easy_publish.release major --branch=master"]
    ]
  end
end
