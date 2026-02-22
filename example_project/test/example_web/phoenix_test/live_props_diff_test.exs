defmodule ExampleWeb.PhoenixTest.LivePropsDiffTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page title and description", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> assert_has("[data-testid='props-diff-page-title']", text: "Props Diff Demo")
    |> assert_has("p", text: "diff on")
  end

  test "renders one component with diff on and one with diff off", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> assert_has("[data-use-diff='true']", count: 1)
    |> assert_has("[data-use-diff='false']", count: 1)
  end

  test "initial props show a=1, b=2, c=3 in data-props", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> assert_has("[data-props*='\"a\":1']", count: 2)
    |> assert_has("[data-props*='\"b\":2']", count: 2)
    |> assert_has("[data-props*='\"c\":3']", count: 2)
  end

  test "Increment A updates server state and data-props", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> click_button("Increment A")
    |> assert_has("[data-props*='\"a\":2']")
    # Server-rendered state line updates immediately
    |> assert_has("p", text: "Server state: A=2, B=2, C=3")
  end

  test "Increment B and C update server state", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> click_button("Increment B")
    |> assert_has("p", text: "Server state: A=1, B=3, C=3")
    |> click_button("Increment C")
    |> assert_has("p", text: "Server state: A=1, B=3, C=4")
  end
end
