defmodule ExampleWeb.LiveStructTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E tests for the /live-struct LiveView (Struct Svelte component with struct props).
  """
  @moduletag :e2e

  test "live-struct page loads and shows Struct Demo", %{session: session} do
    session = visit(session, "/live-struct")

    session |> find(Query.css("h1", text: "Struct Demo"))
    session |> find(Query.css("p", text: "Passing a struct to Svelte."))
  end

  test "struct data flows from LiveView to Svelte component and updates on server events", %{session: session} do
    session = visit(session, "/live-struct")

    # Verify initial struct from LiveView (%User{name: "Bob", age: 42})
    session |> assert_has(Query.css("[data-testid='struct-json']", text: "Bob"))
    session |> assert_has(Query.css("[data-testid='struct-json']", text: "42"))

    # Trigger server-side change and verify it reaches the Svelte component
    session |> click(Query.css("[data-testid='struct-randomize-age']"))

    # Wallaby retries until the element no longer contains "42" (or times out).
    # This can ONLY pass if data actually flows from LiveView → Svelte.
    session |> refute_has(Query.css("[data-testid='struct-json']", text: "42"))
  end
end
