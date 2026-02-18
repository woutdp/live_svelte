defmodule ExampleWeb.PhoenixTest.LiveStructTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-struct")
    |> assert_has("h1", text: "Struct Demo")
    |> assert_has("p", text: "Passing a struct to Svelte.")
  end

  test "renders Struct component with correct shape and initial data", %{conn: conn} do
    conn
    |> visit("/live-struct")
    |> assert_has("[data-name='Struct']")
    # Verify the props contain a "struct" key with "name" and "age" fields
    |> assert_has("[data-props*='\"struct\"']")
    |> assert_has("[data-props*='\"name\":\"Bob\"']")
    |> assert_has("[data-props*='\"age\":42']")
  end

  test "clicking randomize changes the age while preserving the name", %{conn: conn} do
    conn
    |> visit("/live-struct")
    |> assert_has("[data-props*='\"age\":42']")
    |> unwrap(fn view ->
      Phoenix.LiveViewTest.render_click(view, "randomize")
    end)
    # Name should still be Bob
    |> assert_has("[data-props*='\"name\":\"Bob\"']")
    # Age should have changed from 42 (1% chance of flake if random lands on 42)
    |> refute_has("[data-props*='\"age\":42']")
  end
end
