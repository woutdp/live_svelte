defmodule LiveSvelte.MixProject do
  use Mix.Project

  @version "0.1.0-rc0"
  @repo_url "https://github.com/woutdp/live_svelte"

  def project do
    [
      app: :live_svelte,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "E2E reactivity for Svelte and LiveView",
      package: package(),

      # Docs
      name: "LiveSvelte",
      docs: [
        source_ref: "v#{@version}",
        source_url: @repo_url
      ]
    ]
  end

  defp package() do
    [
      maintainers: ["Wout De Puysseleir"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url},
      files: ~w(assets lib LICENSE.MD mix.exs package.json README.md .formatter.exs)
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:jason, "~> 1.2"},
      {:nodejs, "~> 2.0"},
      {:phoenix, "~> 1.17"},
      {:phoenix_live_view, "~> 0.18.3"}
    ]
  end
end
