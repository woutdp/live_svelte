defmodule ExampleWeb.HelloWorldTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E test for the /hello-world page (PageController + HelloWorld Svelte component).
  """

  test "hello-world page loads and shows HelloWorld Svelte content", %{page: page} do
    Page.goto!(page, "/hello-world")

    Expect.to_have_text!(Page.get_by_test_id(page, "hello-world-content"), "Hello World")
  end
end
