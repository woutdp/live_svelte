defmodule Example.LiveSvelteSsrIntegrationTest do
  @moduledoc """
  Verifies the example project exercises the local `live_svelte` checkout (path dep)
  with the ESM SSR fix from issue #133.
  """
  use ExUnit.Case, async: false

  @moduletag :nodejs_ssr

  test "uses local live_svelte path dependency with SSR fix" do
    parent_root = Path.expand("../..", __DIR__)

    assert File.read!(Path.join(parent_root, "lib/ssr/node_js.ex")) =~ "setup_env!"
    assert File.read!(Path.join(parent_root, "lib/ssr/node_js.ex")) =~ "esm: true"

    beam = :code.which(LiveSvelte.SSR.NodeJS) |> to_string()
    assert beam =~ "live_svelte", "expected compiled live_svelte beam, got #{beam}"
  end

  test "local live_svelte exposes SSR fix APIs" do
    assert function_exported?(LiveSvelte.SSR.NodeJS, :setup_env!, 0)
    assert Application.get_env(:live_svelte, :otp_app) == :example
    assert Application.get_env(:live_svelte, :ssr_filepath) == "./svelte/server.mjs"
    refute String.ends_with?(LiveSvelte.SSR.NodeJS.server_path(), "/priv/svelte")
    assert String.ends_with?(LiveSvelte.SSR.NodeJS.server_path(), "/priv")
  end

  test "NodeJS SSR renders via priv/svelte/server.mjs" do
    bundle_path = Path.join(LiveSvelte.SSR.NodeJS.server_path(), "svelte/server.mjs")

    assert File.exists?(bundle_path),
           "SSR bundle missing at #{bundle_path}; run mix assets.build && mix compile"

    original_ssr = Application.get_env(:live_svelte, :ssr, false)
    original_node_env = System.get_env("NODE_ENV")
    original_ssr_node_env = Application.get_env(:live_svelte, :ssr_node_env)

    on_exit(fn ->
      Application.put_env(:live_svelte, :ssr, original_ssr)

      if original_ssr_node_env,
        do: Application.put_env(:live_svelte, :ssr_node_env, original_ssr_node_env),
        else: Application.delete_env(:live_svelte, :ssr_node_env)

      if original_node_env,
        do: System.put_env("NODE_ENV", original_node_env),
        else: System.delete_env("NODE_ENV")
    end)

    Application.put_env(:live_svelte, :ssr, true)
    System.delete_env("NODE_ENV")
    Application.put_env(:live_svelte, :ssr_node_env, "production")
    LiveSvelte.SSR.NodeJS.setup_env!()

    assert System.get_env("NODE_ENV") == "production"

    result = LiveSvelte.SSR.NodeJS.render("SsrDemo", %{"greeting" => "Hello from test!"}, %{})

    assert is_map(result)
    assert result["html"] =~ "Hello from test!"
  end
end
