defmodule LiveSvelte.SSR.NodeJSTest do
  use ExUnit.Case

  alias LiveSvelte.SSR.NodeJS, as: NodeJSRenderer

  @moduletag :nodejs_ssr

  @test_support_path Path.expand("support", __DIR__)
  @test_server_filename "ssr_test_server.mjs"

  describe "setup_env!/0" do
    test "sets NODE_ENV when ssr_node_env is configured and NODE_ENV is unset" do
      original_node_env = System.get_env("NODE_ENV")
      original_ssr_node_env = Application.get_env(:live_svelte, :ssr_node_env)

      on_exit(fn ->
        if original_node_env, do: System.put_env("NODE_ENV", original_node_env), else: System.delete_env("NODE_ENV")
        if original_ssr_node_env, do: Application.put_env(:live_svelte, :ssr_node_env, original_ssr_node_env), else: Application.delete_env(:live_svelte, :ssr_node_env)
      end)

      System.delete_env("NODE_ENV")
      Application.put_env(:live_svelte, :ssr_node_env, "production")

      assert :ok = NodeJSRenderer.setup_env!()
      assert System.get_env("NODE_ENV") == "production"
    end

    test "does not override an existing NODE_ENV" do
      original_node_env = System.get_env("NODE_ENV")
      original_ssr_node_env = Application.get_env(:live_svelte, :ssr_node_env)

      on_exit(fn ->
        if original_node_env, do: System.put_env("NODE_ENV", original_node_env), else: System.delete_env("NODE_ENV")
        if original_ssr_node_env, do: Application.put_env(:live_svelte, :ssr_node_env, original_ssr_node_env), else: Application.delete_env(:live_svelte, :ssr_node_env)
      end)

      System.put_env("NODE_ENV", "test")
      Application.put_env(:live_svelte, :ssr_node_env, "production")

      assert :ok = NodeJSRenderer.setup_env!()
      assert System.get_env("NODE_ENV") == "test"
    end

    test "is a no-op when ssr_node_env is not configured" do
      original_node_env = System.get_env("NODE_ENV")
      original_ssr_node_env = Application.get_env(:live_svelte, :ssr_node_env)

      on_exit(fn ->
        if original_node_env, do: System.put_env("NODE_ENV", original_node_env), else: System.delete_env("NODE_ENV")
        if original_ssr_node_env, do: Application.put_env(:live_svelte, :ssr_node_env, original_ssr_node_env), else: Application.delete_env(:live_svelte, :ssr_node_env)
      end)

      System.delete_env("NODE_ENV")
      Application.delete_env(:live_svelte, :ssr_node_env)

      assert :ok = NodeJSRenderer.setup_env!()
      assert is_nil(System.get_env("NODE_ENV"))
    end
  end

  describe "server_path/0" do
    test "resolves priv/ from configured otp_app" do
      original_otp_app = Application.get_env(:live_svelte, :otp_app)

      on_exit(fn ->
        if original_otp_app,
          do: Application.put_env(:live_svelte, :otp_app, original_otp_app),
          else: Application.delete_env(:live_svelte, :otp_app)
      end)

      Application.put_env(:live_svelte, :otp_app, :live_svelte)

      path = NodeJSRenderer.server_path()
      assert String.ends_with?(path, "/priv")
      refute String.ends_with?(path, "/priv/svelte")
    end
  end

  describe "render/3 with NodeJS.Supervisor running" do
    setup do
      start_supervised!({NodeJS.Supervisor, [path: @test_support_path, pool_size: 1]})

      Application.put_env(:live_svelte, :ssr_filepath, @test_server_filename)

      on_exit(fn ->
        Application.delete_env(:live_svelte, :ssr_filepath)
      end)

      :ok
    end

    test "renders component and returns HTML" do
      result = NodeJSRenderer.render("TestComponent", %{"count" => 42}, %{})

      assert is_binary(result)
      assert result =~ "SSR Rendered: TestComponent"
      assert result =~ "TestComponent"
    end

    test "passes props to the render function" do
      result = NodeJSRenderer.render("MyComponent", %{"name" => "John", "age" => 30}, %{})

      assert result =~ "John"
      assert result =~ "30"
    end

    test "passes slots to the render function" do
      result = NodeJSRenderer.render("SlotComponent", %{}, %{"default" => "<p>Content</p>"})

      assert result =~ "Content"
    end
  end

  describe "render/3 without NodeJS.Supervisor" do
    test "raises NotConfigured when NodeJS.Supervisor is not running" do
      Application.put_env(:live_svelte, :ssr_filepath, @test_server_filename)

      on_exit(fn ->
        Application.delete_env(:live_svelte, :ssr_filepath)
      end)

      assert_raise LiveSvelte.SSR.NotConfigured, ~r/NodeJS is not configured/, fn ->
        NodeJSRenderer.render("TestComponent", %{}, %{})
      end
    end
  end
end
