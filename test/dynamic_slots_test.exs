defmodule LiveSvelte.DynamicSlotsTest do
  use ExUnit.Case, async: true

  describe "__components__/0" do
    test "returns empty map to skip Phoenix validation" do
      # LiveSvelte.__components__() should return %{} so that
      # __components__()[:svelte] returns nil, skipping validation
      assert LiveSvelte.__components__() == %{}
    end

    test "looking up :svelte returns nil" do
      # This is what Phoenix does during validation
      # When it returns nil, validation is skipped
      assert LiveSvelte.__components__()[:svelte] == nil
    end
  end

  describe "slot validation bypass" do
    test "LiveSvelte module has __components__/0 defined" do
      assert function_exported?(LiveSvelte, :__components__, 0)
    end
  end
end
