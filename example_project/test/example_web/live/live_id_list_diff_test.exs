defmodule ExampleWeb.LiveIdListDiffTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E test for the LiveIdListDiff LiveView: verifies that insert/delete/reorder
  operations on an id-keyed list are reflected correctly in the Svelte component.
  """

  defp items(page), do: Page.locator(page, "[data-testid^='item-name-']")

  test "page mounts and shows title", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "id-list-diff-title")
      |> Locator.filter(has_text: "ID-Based List Diffing Demo")
    )
  end

  test "initial list shows Alice, Bob, Carol", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")

    Expect.to_have_text!(Page.get_by_test_id(page, "item-name-1"), "Alice")
    Expect.to_have_text!(Page.get_by_test_id(page, "item-name-2"), "Bob")
    Expect.to_have_text!(Page.get_by_test_id(page, "item-name-3"), "Carol")
  end

  test "Insert Item prepends a new item to the list", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Insert Item"))

    # New item is at the top
    Expect.to_have_count!(items(page), 4)
    Expect.to_have_text!(Locator.first(items(page)), "Item 4")
  end

  test "Delete First removes the first item", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Delete First"))

    # Alice (id=1) was first; after delete, Bob should be first
    Expect.to_have_count!(items(page), 2)
    Expect.to_have_text!(Locator.first(items(page)), "Bob")
  end

  test "Move Last to Top brings Carol to the front", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Move Last to Top"))

    Expect.to_have_count!(items(page), 3)
    Expect.to_have_text!(Locator.first(items(page)), "Carol")
  end

  test "sequential operations maintain correct list state", %{page: page} do
    Page.goto!(page, "/live-id-list-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Insert Item"))
    Locator.click!(Page.get_by_role(page, :button, name: "Delete First"))

    # Inserted item 4 at front, then deleted it — back to original 3 items
    Expect.to_have_count!(items(page), 3)
    Expect.to_have_text!(Locator.first(items(page)), "Alice")
  end
end
