defmodule ExampleWeb.PhoenixTest.LiveRunedTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveRuned (/live-runed).
  Validates server-side rendering, data-props contract, and event handling.
  RunedDemo is browser-only (ssr={false}); these tests validate the LiveView layer only.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  test "renders page heading", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("h1", text: "Runed Utilities")
  end

  test "renders RunedDemo Svelte component with correct props", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("[data-name='RunedDemo']", count: 1)
    |> assert_has("[data-props*='matches']")
    |> assert_has("[data-props*='comboCount']")
  end

  test "initial match count is 20 (all items)", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("[data-testid='match-count']", text: "20")
  end

  test "search event filters matches", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("[data-testid='match-count']", text: "20")
    |> unwrap(fn view ->
      render_click(view, "search", %{"query" => "eli"})
    end)
    |> assert_has("[data-testid='match-count']", text: "1")
  end

  test "resize event updates server-size display", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> unwrap(fn view ->
      render_click(view, "resize", %{"width" => 400, "height" => 200})
    end)
    |> assert_has("[data-testid='server-size']", text: "400×200px")
  end

  test "combo event increments combo-count", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("[data-testid='combo-count']", text: "0")
    |> unwrap(fn view ->
      render_click(view, "combo", %{})
    end)
    |> assert_has("[data-testid='combo-count']", text: "1")
    |> unwrap(fn view ->
      render_click(view, "combo", %{})
    end)
    |> assert_has("[data-testid='combo-count']", text: "2")
  end

  test "server size shows not yet synced initially", %{conn: conn} do
    conn
    |> visit("/live-runed")
    |> assert_has("[data-testid='server-size']", text: "not yet synced")
    |> refute_has("[data-testid='server-size']", text: "px")
  end
end
