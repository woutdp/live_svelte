defmodule ExampleWeb.PhoenixTest.LivePlusMinusTest do
  @moduledoc """
  PhoenixTest (in-process) for LivePlusMinus LiveView (/live-plus-minus).
  Validates that the page renders, initial value is 10, and click_button
  (phx-click) updates the displayed value. Step amount can be tested by
  filling the input and clicking; LiveView receives phx-keyup for amount.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-plus-minus")
    |> assert_has("h2", text: "Plus / Minus (LiveView)")
    |> assert_has("p", text: "Native LiveView: value and step amount are both server state.")
  end

  test "renders initial value and plus/minus buttons", %{conn: conn} do
    conn
    |> visit("/live-plus-minus")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "10")
    |> assert_has("[data-testid='live-plus-minus-minus']")
    |> assert_has("[data-testid='live-plus-minus-plus']")
  end

  test "clicking plus increases value", %{conn: conn} do
    conn
    |> visit("/live-plus-minus")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "10")
    |> click_button("[data-testid='live-plus-minus-plus']", "")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "11")
  end

  test "clicking minus decreases value", %{conn: conn} do
    conn
    |> visit("/live-plus-minus")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "10")
    |> click_button("[data-testid='live-plus-minus-plus']", "")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "11")
    |> click_button("[data-testid='live-plus-minus-minus']", "")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "10")
  end

  test "multiple plus clicks increase value", %{conn: conn} do
    conn
    |> visit("/live-plus-minus")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "10")
    |> click_button("[data-testid='live-plus-minus-plus']", "")
    |> click_button("[data-testid='live-plus-minus-plus']", "")
    |> click_button("[data-testid='live-plus-minus-plus']", "")
    |> assert_has("[data-testid='live-plus-minus-value']", text: "13")
  end
end
