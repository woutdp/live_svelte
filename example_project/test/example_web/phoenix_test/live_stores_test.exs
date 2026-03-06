defmodule ExampleWeb.PhoenixTest.LiveStoresTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveStores (/live-stores).
  Validates server-side rendering, data-props contract, and sync_store event handling.
  Store sharing between instances is client-only; these tests validate the LiveView layer.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  test "renders page heading", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> assert_has("h1", text: "Svelte Stores")
  end

  test "renders two StoreCounter components", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> assert_has("[data-name='StoreCounter']", count: 2)
  end

  test "both components receive label prop", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> assert_has("[data-props*='Instance A']")
    |> assert_has("[data-props*='Instance B']")
  end

  test "server value shows not yet synced initially", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> assert_has("[data-testid='server-value']", text: "not yet synced")
  end

  test "initial sync count is 0", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> assert_has("[data-testid='sync-count']", text: "0")
  end

  test "sync_store event updates server value", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> unwrap(fn view ->
      render_click(view, "sync_store", %{"value" => 42})
    end)
    |> assert_has("[data-testid='server-value']", text: "42")
  end

  test "sync_store event increments sync count", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> unwrap(fn view -> render_click(view, "sync_store", %{"value" => 1}) end)
    |> assert_has("[data-testid='sync-count']", text: "1")
    |> unwrap(fn view -> render_click(view, "sync_store", %{"value" => 2}) end)
    |> assert_has("[data-testid='sync-count']", text: "2")
  end

  test "sync_store event replaces previous server value", %{conn: conn} do
    conn
    |> visit("/live-stores")
    |> unwrap(fn view -> render_click(view, "sync_store", %{"value" => 5}) end)
    |> assert_has("[data-testid='server-value']", text: "5")
    |> unwrap(fn view -> render_click(view, "sync_store", %{"value" => 99}) end)
    |> assert_has("[data-testid='server-value']", text: "99")
  end
end
