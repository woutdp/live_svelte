defmodule ExampleWeb.PhoenixTest.LodashTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders the Lodash Svelte component with the unordered array in props", %{conn: conn} do
    conn
    |> visit("/lodash")
    |> assert_has("[data-name='Lodash']")
    |> assert_has("[data-props*='[10,50,25,1,3,100,40,30]']")
  end
end
