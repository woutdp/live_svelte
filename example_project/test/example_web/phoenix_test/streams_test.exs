defmodule ExampleWeb.PhoenixTest.StreamsTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page title", %{conn: conn} do
    conn
    |> visit("/streams")
    |> assert_has("[data-testid='streams-page-title']", text: "Phoenix Streams Demo")
  end

  test "initial render has data-streams-diff attribute", %{conn: conn} do
    conn
    |> visit("/streams")
    |> assert_has("[data-streams-diff]")
  end

  test "data-streams-diff is a non-empty JSON array on initial render", %{conn: conn} do
    session =
      conn
      |> visit("/streams")

    # The data-streams-diff attribute should contain JSON with upsert ops for the 3 initial items
    session
    |> assert_has("[data-streams-diff*='upsert']")
  end

  test "data-streams-diff contains initial items with __dom_id", %{conn: conn} do
    conn
    |> visit("/streams")
    |> assert_has("[data-streams-diff*='items-1']")
    |> assert_has("[data-streams-diff*='items-2']")
    |> assert_has("[data-streams-diff*='items-3']")
  end

  test "data-streams-diff contains reset op (replace) on initial render", %{conn: conn} do
    conn
    |> visit("/streams")
    |> assert_has("[data-streams-diff*='replace']")
  end

  test "component renders with correct stream name attribute", %{conn: conn} do
    conn
    |> visit("/streams")
    |> assert_has("[data-name='StreamDemo']")
  end
end
