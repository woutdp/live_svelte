defmodule LiveSvelte.SSR.DenoTest do
  # must be synchronous — tests are sensitive to config changes
  use ExUnit.Case, async: false

  describe "render/3" do
    test "raises NotConfigured when DenoRider process is not running" do
      assert_raise(LiveSvelte.SSR.NotConfigured, fn ->
        LiveSvelte.SSR.Deno.render("Counter", %{count: 0}, %{})
      end)
    end
  end

  test "server_path/0 returns a binary" do
    assert is_binary(LiveSvelte.SSR.Deno.server_path())
  end

  test "implements LiveSvelte.SSR behaviour" do
    Code.ensure_loaded!(LiveSvelte.SSR.Deno)
    assert function_exported?(LiveSvelte.SSR.Deno, :render, 3)
  end
end
