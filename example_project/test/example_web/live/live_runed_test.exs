defmodule ExampleWeb.LiveRunedTest do
  @moduledoc """
  E2E tests for the /live-runed LiveView with the RunedDemo Svelte component.
  Validates the full pipeline: LiveView → LiveSvelte hook → Svelte mounts runed utilities.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page loads and shows heading", %{page: page} do
    Page.goto!(page, "/live-runed")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Runed Utilities"))
  end

  test "search input renders after Svelte mounts", %{page: page} do
    Page.goto!(page, "/live-runed")

    Expect.to_be_visible!(Page.get_by_test_id(page, "search-input"))
  end

  test "resizable element renders after Svelte mounts", %{page: page} do
    Page.goto!(page, "/live-runed")

    Expect.to_be_visible!(Page.get_by_test_id(page, "resizable-element"))
  end

  test "pressed-keys container renders after Svelte mounts", %{page: page} do
    Page.goto!(page, "/live-runed")

    Expect.to_be_visible!(Page.get_by_test_id(page, "pressed-keys"))
  end
end
