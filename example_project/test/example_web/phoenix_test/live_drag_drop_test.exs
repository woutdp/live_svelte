defmodule ExampleWeb.PhoenixTest.LiveDragDropTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveDragDrop (/live-drag-drop).
  Validates that the page renders, the DragDrop Svelte component receives the
  initial items as props, and that the reorder event updates the server-side order.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  @initial_items [
    "Design mockups",
    "Set up database",
    "Write API endpoints",
    "Build frontend",
    "Write tests",
    "Deploy to production"
  ]

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("h1", text: "Drag & Drop Demo")
    |> assert_has("p",
      text: "Reorder tasks with drag and drop. The new order is synced to the server via pushEvent."
    )
  end

  test "renders DragDrop Svelte component with initial items in props", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("[data-name='DragDrop']", count: 1)
    |> assert_has("[data-props*='\"id\":1']")
    |> assert_has("[data-props*='Design mockups']")
  end

  test "server order list renders all initial items", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("[data-testid='server-order-item']", count: 6)
    |> assert_has("[data-testid='server-order-list'] li:first-child",
      text: "Design mockups"
    )
  end

  test "all initial task names appear in the server order list", %{conn: conn} do
    session = conn |> visit("/live-drag-drop")

    Enum.each(@initial_items, fn name ->
      assert_has(session, "[data-testid='server-order-item']", text: name)
    end)
  end

  test "reorder event updates server-side item order", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("[data-testid='server-order-list'] li:first-child", text: "Design mockups")
    |> unwrap(fn view ->
      render_click(view, "reorder", %{"ids" => [2, 1, 3, 4, 5, 6]})
    end)
    |> assert_has("[data-testid='server-order-item']", count: 6)
    |> assert_has("[data-testid='server-order-list'] li:first-child", text: "Set up database")
  end

  test "reorder event updates data-props to reflect new order", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("[data-props*='\"id\":1']")
    |> unwrap(fn view ->
      render_click(view, "reorder", %{"ids" => [2, 1, 3, 4, 5, 6]})
    end)
    |> assert_has("[data-name='DragDrop']", count: 1)
    |> assert_has("[data-props*='\"id\":2']")
  end

  test "multiple reorders keep all 6 items in server order list", %{conn: conn} do
    conn
    |> visit("/live-drag-drop")
    |> assert_has("[data-testid='server-order-item']", count: 6)
    |> unwrap(fn view ->
      render_click(view, "reorder", %{"ids" => [6, 5, 4, 3, 2, 1]})
    end)
    |> assert_has("[data-testid='server-order-item']", count: 6)
    |> assert_has("[data-testid='server-order-list'] li:first-child",
      text: "Deploy to production"
    )
    |> unwrap(fn view ->
      render_click(view, "reorder", %{"ids" => [1, 2, 3, 4, 5, 6]})
    end)
    |> assert_has("[data-testid='server-order-item']", count: 6)
    |> assert_has("[data-testid='server-order-list'] li:first-child", text: "Design mockups")
  end
end
