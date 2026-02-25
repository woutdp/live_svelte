defmodule LiveSvelte.SSR.ViteJSTest do
  # must be synchronous — tests are sensitive to config changes
  use ExUnit.Case, async: false

  setup do
    original = Application.get_env(:live_svelte, :vite_host)

    on_exit(fn ->
      if original == nil do
        Application.delete_env(:live_svelte, :vite_host)
      else
        Application.put_env(:live_svelte, :vite_host, original)
      end
    end)

    :ok
  end

  describe "vite_path/1" do
    test "returns correct URL when vite_host is configured" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")
      assert LiveSvelte.SSR.ViteJS.vite_path("/ssr_render") == "http://localhost:5173/ssr_render"
    end

    test "appends path to host without double slash" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")
      assert LiveSvelte.SSR.ViteJS.vite_path("/foo") == "http://localhost:5173/foo"
    end

    test "raises NotConfigured when vite_host is not set" do
      Application.delete_env(:live_svelte, :vite_host)

      assert_raise(LiveSvelte.SSR.NotConfigured, fn ->
        LiveSvelte.SSR.ViteJS.vite_path("/ssr_render")
      end)
    end
  end

  describe "render/3" do
    test "raises NotConfigured when vite_host is not configured" do
      Application.delete_env(:live_svelte, :vite_host)

      assert_raise(LiveSvelte.SSR.NotConfigured, fn ->
        LiveSvelte.SSR.ViteJS.render("Counter", %{count: 0}, nil)
      end)
    end

    test "raises NotConfigured when Vite server is unreachable" do
      # Use a port that is guaranteed to be closed
      Application.put_env(:live_svelte, :vite_host, "http://127.0.0.1:59998")

      assert_raise(LiveSvelte.SSR.NotConfigured, fn ->
        LiveSvelte.SSR.ViteJS.render("Counter", %{count: 0}, nil)
      end)
    end
  end

  test "implements LiveSvelte.SSR behaviour" do
    assert function_exported?(LiveSvelte.SSR.ViteJS, :render, 3)
  end
end
