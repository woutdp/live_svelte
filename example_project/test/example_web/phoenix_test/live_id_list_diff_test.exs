defmodule ExampleWeb.PhoenixTest.LiveIdListDiffTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page title", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> assert_has("[data-testid='id-list-diff-title']", text: "ID-Based List Diffing Demo")
  end

  test "initial data-props contains 3 items with ids 1, 2, 3", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> assert_has("[data-props*='\"id\":1']")
    |> assert_has("[data-props*='\"id\":2']")
    |> assert_has("[data-props*='\"id\":3']")
  end

  test "data-use-diff is true by default", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> assert_has("[data-use-diff='true']")
  end

  test "Insert Item adds a new item to data-props", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> click_button("Insert Item")
    |> assert_has("[data-props*='\"id\":4,']")
    |> assert_has("p", text: "Item count: 4")
  end

  test "Delete First removes the first item", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> click_button("Delete First")
    |> assert_has("p", text: "Item count: 2")
  end

  test "Move Last to Top reorders items", %{conn: conn} do
    conn
    |> visit("/live-id-list-diff")
    |> click_button("Move Last to Top")
    |> assert_has("[data-props*='\"id\":3']")
    |> assert_has("p", text: "Item count: 3")
  end
end
