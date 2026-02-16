defmodule ExampleWeb.PhoenixTest.LiveStaticColorTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("h2", text: "Static color")
    |> assert_has("p", text: "Svelte components rendered inside a for loop")
  end

  test "renders three Static Svelte components initially with white color", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-name='Static']", count: 3)
    |> assert_has("[data-props*='\"color\":\"white\"']", count: 3)
  end

  test "each Svelte component receives its index in props", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-props*='\"index\":0']")
    |> assert_has("[data-props*='\"index\":1']")
    |> assert_has("[data-props*='\"index\":2']")
  end

  test "adding an element increases Svelte component count by one", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-name='Static']", count: 3)
    |> click_button("Add Element")
    |> assert_has("[data-name='Static']", count: 4)
  end

  test "adding an element preserves existing components and adds index 3", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Add Element")
    |> assert_has("[data-props*='\"index\":0']")
    |> assert_has("[data-props*='\"index\":1']")
    |> assert_has("[data-props*='\"index\":2']")
    |> assert_has("[data-props*='\"index\":3']")
  end

  test "clicking red updates all Svelte component props to red", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Change color to red")
    |> assert_has("[data-props*='\"color\":\"red\"']", count: 3)
    |> refute_has("[data-props*='\"color\":\"white\"']")
  end

  test "clicking blue updates all Svelte component props to blue", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Change color to blue")
    |> assert_has("[data-props*='\"color\":\"blue\"']", count: 3)
    |> refute_has("[data-props*='\"color\":\"white\"']")
  end

  test "adding elements after color change preserves color for all components", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Change color to red")
    |> click_button("Add Element")
    |> assert_has("[data-name='Static']", count: 4)
    |> assert_has("[data-props*='\"color\":\"red\"']", count: 4)
  end
end
