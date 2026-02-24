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

  test "global enable_props_diff false sets all components to data-use-diff false", %{conn: conn} do
    Application.put_env(:live_svelte, :enable_props_diff, false)

    try do
      conn
      |> visit("/live-props-diff")
      |> refute_has("[data-use-diff='true']")
      |> assert_has("[data-use-diff='false']", count: 2)
    after
      Application.put_env(:live_svelte, :enable_props_diff, true)
    end
  end

  test "second sequential update also sends only changed keys in diff-on", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> click_button("Increment A")
    |> click_button("Increment A")
    # diff-on: second update still sends only the changed key (process dict tracking intact)
    |> assert_has("[data-use-diff='true'][data-props*='\"a\":3']")
    |> refute_has("[data-use-diff='true'][data-props*='\"b\":2']")
    # diff-off: all props present with current values
    |> assert_has("[data-use-diff='false'][data-props*='\"a\":3']")
    |> assert_has("[data-use-diff='false'][data-props*='\"b\":2']")
  end

  test "after update diff-off component has full props, diff-on has only changed keys", %{conn: conn} do
    conn
    |> visit("/live-props-diff")
    |> click_button("Increment A")
    # diff-off (graceful fallback = full replace): all props present including updated a
    |> assert_has("[data-use-diff='false'][data-props*='\"a\":2']")
    |> assert_has("[data-use-diff='false'][data-props*='\"b\":2']")
    |> assert_has("[data-use-diff='false'][data-props*='\"c\":3']")
    # diff-on: changed key IS present, unchanged b and c are absent
    |> assert_has("[data-use-diff='true'][data-props*='\"a\":2']")
    |> refute_has("[data-use-diff='true'][data-props*='\"b\":2']")
    |> refute_has("[data-use-diff='true'][data-props*='\"c\":3']")
  end
end
