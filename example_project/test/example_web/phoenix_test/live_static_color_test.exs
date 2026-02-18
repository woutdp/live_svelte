defmodule ExampleWeb.PhoenixTest.LiveStaticColorTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("h1", text: "Static Color Demo")
    |> assert_has("p", text: "Passing dynamic props to a list of Svelte components from LiveView.")
  end

  test "renders both Svelte mountpoints (file-based + ~V sigil) initially with white color", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-name='Static']", count: 3)
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveStaticColor']", count: 3)
    |> assert_has("[data-props*='\"color\":\"white\"']", count: 6)
  end

  test "each Svelte component receives its index in props (twice: file-based + ~V sigil)", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-props*='\"index\":0']", count: 2)
    |> assert_has("[data-props*='\"index\":1']", count: 2)
    |> assert_has("[data-props*='\"index\":2']", count: 2)
  end

  test "adding an element increases both mountpoint counts by one", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> assert_has("[data-name='Static']", count: 3)
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveStaticColor']", count: 3)
    |> click_button("Add Element")
    |> assert_has("[data-name='Static']", count: 4)
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveStaticColor']", count: 4)
  end

  test "adding an element preserves existing indices and adds index 3 twice", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Add Element")
    |> assert_has("[data-props*='\"index\":0']", count: 2)
    |> assert_has("[data-props*='\"index\":1']", count: 2)
    |> assert_has("[data-props*='\"index\":2']", count: 2)
    |> assert_has("[data-props*='\"index\":3']", count: 2)
  end

  test "clicking red updates all Svelte components to red", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Change color to red")
    |> assert_has("[data-props*='\"color\":\"red\"']", count: 6)
    |> refute_has("[data-props*='\"color\":\"white\"']")
  end

  test "adding elements after color change preserves color for all components", %{conn: conn} do
    conn
    |> visit("/live-static-color")
    |> click_button("Change color to red")
    |> click_button("Add Element")
    |> assert_has("[data-name='Static']", count: 4)
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveStaticColor']", count: 4)
    |> assert_has("[data-props*='\"color\":\"red\"']", count: 8)
  end
end
