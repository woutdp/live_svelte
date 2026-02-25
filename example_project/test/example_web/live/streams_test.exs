defmodule ExampleWeb.StreamsTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E tests for the Streams LiveView: verifies that Phoenix stream items are rendered
  correctly in the Svelte StreamDemo component with insert, delete, and reset behavior.
  """
  @moduletag :e2e

  test "renders initial 3 stream items", %{session: session} do
    session
    |> visit("/streams")
    |> find(Query.css("[data-testid='item-1']"))
    |> find(Query.css("[data-testid='item-name-1']", text: "Item 1"))

    session
    |> find(Query.css("[data-testid='item-2']"))
    |> find(Query.css("[data-testid='item-name-2']", text: "Item 2"))

    session
    |> find(Query.css("[data-testid='item-3']"))
    |> find(Query.css("[data-testid='item-name-3']", text: "Item 3"))
  end

  test "adds new item to stream", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> fill_in(Query.css("[data-testid='name-input']"), with: "New Item")
      |> fill_in(Query.css("[data-testid='description-input']"), with: "A new description")
      |> click(Query.css("[data-testid='add-button']"))

    session |> find(Query.css("[data-testid='item-4']"))
    session |> find(Query.css("[data-testid='item-name-4']", text: "New Item"))
  end

  test "removes item from stream", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> click(Query.css("[data-testid='remove-2']"))

    # Item 1 and 3 still visible
    session |> find(Query.css("[data-testid='item-1']"))
    session |> find(Query.css("[data-testid='item-3']"))

    # Item 2 is gone
    items = all(session, Query.css("[data-testid='item-2']"))
    assert items == []
  end

  test "clears entire stream", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> click(Query.css("[data-testid='clear-button']"))

    session |> find(Query.css("[data-testid='empty-message']", text: "No items in the stream"))

    items = all(session, Query.css("[data-testid='item-1']"))
    assert items == []
  end

  test "resets stream with at: -1 restores items in append order", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> click(Query.css("[data-testid='clear-button']"))
      |> click(Query.css("[data-testid='reset-button']"))

    # All 3 items back
    session |> find(Query.css("[data-testid='item-1']"))
    session |> find(Query.css("[data-testid='item-2']"))
    session |> find(Query.css("[data-testid='item-3']"))

    # Empty message gone
    empty_items = all(session, Query.css("[data-testid='empty-message']"))
    assert empty_items == []

    # Order: Item 1, Item 2, Item 3 (append order)
    names = all(session, Query.css("[data-testid^='item-name-']"))
    name_texts = Enum.map(names, &Wallaby.Element.text/1)
    assert name_texts == ["Item 1", "Item 2", "Item 3"]
  end

  test "resets stream with at: 0 restores items in prepend order", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> click(Query.css("[data-testid='clear-button']"))
      |> click(Query.css("[data-testid='reset-button-at-0']"))

    # All 3 items back but in reversed order (each prepended at 0)
    names = all(session, Query.css("[data-testid^='item-name-']"))
    name_texts = Enum.map(names, &Wallaby.Element.text/1)
    assert name_texts == ["Item 3", "Item 2", "Item 1"]
  end

  test "updating existing item updates in place without duplication (AC7)", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> click(Query.css("[data-testid='update-1']"))

    # Still exactly 3 items — no duplication
    session |> find(Query.css("[data-testid='item-1']"))
    session |> find(Query.css("[data-testid='item-2']"))
    session |> find(Query.css("[data-testid='item-3']"))

    # Item 1 name is updated (not duplicated)
    session |> find(Query.css("[data-testid='item-name-1']", text: "Updated 1"))

    # Item count shows 3, not 4
    session |> find(Query.css("[data-testid='item-count']", text: "Items (3)"))
  end

  test "stream limit enforced: capped insert keeps only last 3 items", %{session: session} do
    session =
      session
      |> visit("/streams")
      # Initial state: items 1, 2, 3. Click "Add Capped (max 3)" once to add item 4.
      # With limit: -3, the stream keeps the last 3 → items 2, 3, 4.
      |> click(Query.css("[data-testid='add-capped-button']"))

    # Items 2, 3, 4 are present
    session |> find(Query.css("[data-testid='item-2']"))
    session |> find(Query.css("[data-testid='item-3']"))
    session |> find(Query.css("[data-testid='item-4']"))

    # Item 1 was evicted by the limit
    items_1 = all(session, Query.css("[data-testid='item-1']"))
    assert items_1 == []

    # Total item count is 3
    session |> find(Query.css("[data-testid='item-count']", text: "Items (3)"))
  end

  test "sequential add and remove maintains correct state", %{session: session} do
    session =
      session
      |> visit("/streams")
      |> fill_in(Query.css("[data-testid='name-input']"), with: "Item 4")
      |> fill_in(Query.css("[data-testid='description-input']"), with: "Fourth")
      |> click(Query.css("[data-testid='add-button']"))
      |> click(Query.css("[data-testid='remove-2']"))

    # Items 1, 3, 4 remain; item 2 removed
    session |> find(Query.css("[data-testid='item-1']"))
    session |> find(Query.css("[data-testid='item-3']"))
    session |> find(Query.css("[data-testid='item-4']"))

    items_2 = all(session, Query.css("[data-testid='item-2']"))
    assert items_2 == []
  end
end
