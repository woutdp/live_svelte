defmodule ExampleWeb.LiveDragDropTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E tests for the /live-drag-drop LiveView with the DragDrop Svelte component.
  Validates the full stack: LiveView → LiveSvelte hook → Svelte component renders items.
  """
  @moduletag :e2e

  @item_names [
    "Design mockups",
    "Set up database",
    "Write API endpoints",
    "Build frontend",
    "Write tests",
    "Deploy to production"
  ]

  test "page loads and shows heading and description", %{session: session} do
    session = visit(session, "/live-drag-drop")

    session |> assert_has(Query.css("h1", text: "Drag & Drop Demo"))

    session
    |> assert_has(
      Query.css("p",
        text:
          "Reorder tasks with drag and drop. The new order is synced to the server via pushEvent."
      )
    )
  end

  test "DragDrop Svelte component mounts and renders all 6 task items", %{session: session} do
    session = visit(session, "/live-drag-drop")

    # Wait for Svelte to mount and render the drag items
    session = wait_for_drag_items(session, 6)

    items = session |> all(Query.css("[data-testid='drag-item-name']"))
    assert length(items) == 6

    names = Enum.map(items, &Wallaby.Element.text/1)
    assert Enum.sort(names) == Enum.sort(@item_names)
  end

  test "server order list renders all initial items in correct order", %{session: session} do
    session = visit(session, "/live-drag-drop")

    session |> assert_has(Query.css("[data-testid='server-order-item']", count: 6))

    items = session |> all(Query.css("[data-testid='server-order-item']"))
    names = Enum.map(items, &Wallaby.Element.text/1)

    assert names == @item_names
  end

  test "all task names are rendered by Svelte component", %{session: session} do
    session = visit(session, "/live-drag-drop")
    session = wait_for_drag_items(session, 6)

    Enum.each(@item_names, fn name ->
      session |> assert_has(Query.css("[data-testid='drag-item-name']", text: name))
    end)
  end

  defp wait_for_drag_items(session, expected, attempts \\ 80) do
    count = session |> all(Query.css("[data-testid='drag-item-name']")) |> length()

    cond do
      count >= expected ->
        session

      attempts == 0 ->
        raise "timeout waiting for #{expected} drag items, got #{count}"

      true ->
        :timer.sleep(100)
        wait_for_drag_items(session, expected, attempts - 1)
    end
  end
end
