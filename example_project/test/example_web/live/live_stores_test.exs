defmodule ExampleWeb.LiveStoresTest do
  @moduledoc """
  E2E tests for the /live-stores LiveView with the StoreCounter Svelte component.
  The key assertion: both component instances share the same writable store —
  incrementing in one card immediately updates the other.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page loads and shows heading", %{session: session} do
    session
    |> visit("/live-stores")
    |> assert_has(Query.css("h1", text: "Svelte Stores"))
  end

  test "both StoreCounter instances render", %{session: session} do
    session
    |> visit("/live-stores")
    |> assert_has(Query.css("[data-testid='store-instance-1']"))
    |> assert_has(Query.css("[data-testid='store-instance-2']"))
  end

  test "both instances show initial count of 0", %{session: session} do
    session = visit(session, "/live-stores")

    # Wait for Svelte to mount
    session |> find(Query.css("[data-testid='store-count']", count: 2))

    counts = all(session, Query.css("[data-testid='store-count']"))
    assert Enum.map(counts, &Wallaby.Element.text/1) == ["0", "0"]
  end

  test "incrementing in instance 1 updates both components (store is shared)", %{
    session: session
  } do
    session = visit(session, "/live-stores")

    # Wait for both components to mount
    session |> find(Query.css("[data-testid='store-count']", count: 2))

    # Click +1 inside instance 1 only
    instance1 = find(session, Query.css("[data-testid='store-instance-1']"))
    click(instance1, Query.css("[data-testid='store-increment']"))

    # Both counters must now show 1 — the store is shared
    session |> find(Query.css("[data-testid='store-count']", count: 2, minimum: 2))
    counts = all(session, Query.css("[data-testid='store-count']"))
    assert Enum.map(counts, &Wallaby.Element.text/1) == ["1", "1"]
  end

  test "reset button sets store back to 0 in both components", %{session: session} do
    session = visit(session, "/live-stores")

    session |> find(Query.css("[data-testid='store-count']", count: 2))

    # Increment via instance 2, then reset via instance 1
    instance2 = find(session, Query.css("[data-testid='store-instance-2']"))
    click(instance2, Query.css("[data-testid='store-increment']"))

    instance1 = find(session, Query.css("[data-testid='store-instance-1']"))
    click(instance1, Query.css("[data-testid='store-reset']"))

    counts = all(session, Query.css("[data-testid='store-count']"))
    assert Enum.map(counts, &Wallaby.Element.text/1) == ["0", "0"]
  end
end
