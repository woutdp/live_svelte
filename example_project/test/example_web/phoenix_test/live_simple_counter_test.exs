defmodule ExampleWeb.PhoenixTest.LiveSimpleCounterTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("h1", text: "Simple Counter Demo")
    |> assert_has("p", text: "Same LiveView state drives the native counter and both Svelte components.")
  end

  test "renders initial counter and two SimpleCounter Svelte components", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> assert_has("[data-name='SimpleCounter']", count: 2)
    |> assert_has("[data-props*='\"number\":10']", count: 2)
  end

  test "clicking +1 updates LiveView and Svelte component props", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "11")
    |> assert_has("[data-props*='\"number\":11']", count: 2)
  end
end
