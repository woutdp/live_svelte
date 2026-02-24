defmodule ExampleWeb.LiveIdListDiffTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LiveIdListDiff LiveView: verifies that insert/delete/reorder
  operations on an id-keyed list are reflected correctly in the Svelte component.
  """
  @moduletag :e2e

  test "page mounts and shows title", %{session: session} do
    session
    |> visit("/live-id-list-diff")
    |> find(Query.css("[data-testid='id-list-diff-title']", text: "ID-Based List Diffing Demo"))
  end

  test "initial list shows Alice, Bob, Carol", %{session: session} do
    session = visit(session, "/live-id-list-diff")

    assert session |> find(Query.css("[data-testid='item-name-1']")) |> Wallaby.Element.text() ==
             "Alice"

    assert session |> find(Query.css("[data-testid='item-name-2']")) |> Wallaby.Element.text() ==
             "Bob"

    assert session |> find(Query.css("[data-testid='item-name-3']")) |> Wallaby.Element.text() ==
             "Carol"
  end

  test "Insert Item prepends a new item to the list", %{session: session} do
    session =
      session
      |> visit("/live-id-list-diff")
      |> click(Query.button("Insert Item"))

    items = session |> all(Query.css("[data-testid^='item-name-']"))
    assert length(items) == 4

    # New item is at the top
    assert hd(items) |> Wallaby.Element.text() == "Item 4"
  end

  test "Delete First removes the first item", %{session: session} do
    session =
      session
      |> visit("/live-id-list-diff")
      |> click(Query.button("Delete First"))

    items = session |> all(Query.css("[data-testid^='item-name-']"))
    assert length(items) == 2

    # Alice (id=1) was first; after delete, Bob should be first
    assert hd(items) |> Wallaby.Element.text() == "Bob"
  end

  test "Move Last to Top brings Carol to the front", %{session: session} do
    session =
      session
      |> visit("/live-id-list-diff")
      |> click(Query.button("Move Last to Top"))

    items = session |> all(Query.css("[data-testid^='item-name-']"))
    assert length(items) == 3
    assert hd(items) |> Wallaby.Element.text() == "Carol"
  end

  test "sequential operations maintain correct list state", %{session: session} do
    session =
      session
      |> visit("/live-id-list-diff")
      |> click(Query.button("Insert Item"))
      |> click(Query.button("Delete First"))

    items = session |> all(Query.css("[data-testid^='item-name-']"))
    assert length(items) == 3

    # Inserted item 4 at front, then deleted it — back to original 3 items
    assert hd(items) |> Wallaby.Element.text() == "Alice"
  end
end
