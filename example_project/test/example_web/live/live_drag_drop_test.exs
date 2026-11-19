defmodule ExampleWeb.LiveDragDropTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E tests for the /live-drag-drop LiveView with the DragDrop Svelte component.
  Validates the full stack: LiveView → LiveSvelte hook → Svelte component renders items.
  """

  @item_names [
    "Design mockups",
    "Set up database",
    "Write API endpoints",
    "Build frontend",
    "Write tests",
    "Deploy to production"
  ]

  test "page loads and shows heading and description", %{page: page} do
    Page.goto!(page, "/live-drag-drop")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Drag & Drop Demo"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text:
          "Reorder tasks with drag and drop. The new order is synced to the server via pushEvent."
      )
    )
  end

  test "DragDrop Svelte component mounts and renders all 6 task items", %{page: page} do
    Page.goto!(page, "/live-drag-drop")

    # Svelte mounts and renders the drag items
    items = Page.get_by_test_id(page, "drag-item-name")
    Expect.to_have_count!(items, 6)

    names = Locator.all_text_contents!(items)
    assert Enum.sort(names) == Enum.sort(@item_names)
  end

  test "server order list renders all initial items in correct order", %{page: page} do
    Page.goto!(page, "/live-drag-drop")

    items = Page.get_by_test_id(page, "server-order-item")
    Expect.to_have_count!(items, 6)
    Expect.to_have_text!(items, @item_names)
  end

  test "all task names are rendered by Svelte component", %{page: page} do
    Page.goto!(page, "/live-drag-drop")

    Enum.each(@item_names, fn name ->
      Expect.to_be_visible!(
        Page.get_by_test_id(page, "drag-item-name")
        |> Locator.filter(has_text: name)
      )
    end)
  end
end
