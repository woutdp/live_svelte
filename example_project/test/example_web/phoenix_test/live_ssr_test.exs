defmodule ExampleWeb.LiveSsrTest do
  use ExampleWeb.ConnCase, async: true
  @moduletag :phoenix_test

  import PhoenixTest

  test "renders SSR demo page", %{conn: conn} do
    conn
    |> visit("/live-ssr")
    |> assert_has("h2", text: "SSR Demo")
    |> assert_has("[data-props*='greeting']")
  end
end
