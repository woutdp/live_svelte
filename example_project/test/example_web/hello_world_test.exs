defmodule ExampleWeb.HelloWorldTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the /hello-world page (PageController + HelloWorld Svelte component).
  """
  @moduletag :e2e

  test "hello-world page loads and shows HelloWorld Svelte content", %{session: session} do
    session = visit(session, "/hello-world")

    # Svelte component mounts into data-svelte-target; find by testid so we wait for client-side mount
    el = session |> find(Query.css("[data-testid='hello-world-content']"))
    assert Wallaby.Element.text(el) == "Hello World"
  end
end
