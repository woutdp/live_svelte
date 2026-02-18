defmodule ExampleWeb.PhoenixTest.HelloWorldTest do
  use ExampleWeb.ConnCase
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders the HelloWorld Svelte component wrapper", %{conn: conn} do
    conn
    |> visit("/hello-world")
    |> assert_has("[data-name='HelloWorld']")
  end
end
