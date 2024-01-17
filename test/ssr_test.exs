defmodule LiveSvelte.SSRTest do
  # must be synchronous, tests are sensitive to config changes
  use ExUnit.Case, async: false

  test "Node.js is used by default for SSR" do
    load_config("config/config.exs")
    assert Application.get_env(:live_svelte, :ssr_module) == LiveSvelte.SSR.NodeJS
  end

  test "Node.js raises the correct exception" do
    load_config("config/config.exs")

    assert_raise(LiveSvelte.SSR.NotConfigured, fn ->
      LiveSvelte.SSR.NodeJS.render("Test", %{}, %{})
    end)
  end

  test "It uses a different SSR module" do
    load_config("test/ssr_test/test_config.exs")
    assert Application.get_env(:live_svelte, :ssr_module) == SomeOtherSSRModule
  end

  # evil
  # "reloads" configuration by taking all current application configs
  # and merging them with the newly-loaded config file and stuffing
  # them back into the application env
  defp load_config(path) do
    Application.started_applications(:infinity)
    |> Enum.reduce([], fn {app, _, _}, acc ->
      [{app, Application.get_all_env(app)} | acc]
    end)
    |> Config.Reader.merge(Config.Reader.read!(path))
    |> Application.put_all_env()
  end
end
