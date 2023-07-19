defmodule LiveSvelte.MixProject do
  use Mix.Project

  @version "0.9.0"
  @repo_url "https://github.com/woutdp/live_svelte"

  def project do
    [
      app: :live_svelte,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

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
        extras: ["README.md"],
        links: %{
          "GitHub" => @repo_url,
          "Sponsor" => "https://github.com/sponsors/woutdp"
        }
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
        ~w(priv assets lib mix.exs package.json .formatter.exs LICENSE.md README.md CHANGELOG.md)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:nodejs, "~> 2.0"},
      {:phoenix, ">= 1.7.0"},
      {:phoenix_html, ">= 3.3.1"},
      {:phoenix_live_view, ">= 0.18.0"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "assets.build": ["esbuild module", "esbuild cdn", "esbuild cdn_min", "esbuild main"],
      "assets.watch": [
        "esbuild module --watch",
        "esbuild cdn --watch",
        "esbuild cdn_min --watch",
        "esbuild main --watch"
      ]
    ]
  end
end
