defmodule ExampleWeb.LiveEditorTest do
  @moduledoc """
  E2E tests for the /live-editor LiveView with the RichEditor Svelte component.
  Validates the full pipeline: LiveView → LiveSvelte hook → Svelte mounts Editor.js via @attach.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page loads and shows heading", %{page: page} do
    Page.goto!(page, "/live-editor")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Rich Editor (@attach)"))
  end

  test "editor container renders after Svelte mounts", %{page: page} do
    Page.goto!(page, "/live-editor")

    Expect.to_be_visible!(Page.get_by_test_id(page, "editor-container"))
  end

  test "save button is rendered by Svelte", %{page: page} do
    Page.goto!(page, "/live-editor")

    Expect.to_be_visible!(Page.get_by_test_id(page, "editor-save-btn"))
  end
end
