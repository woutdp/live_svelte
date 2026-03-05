defmodule ExampleWeb.Live.LiveSsrTest do
  @moduledoc """
  E2E test for the LiveSsr LiveView (/live-ssr).
  Validates that the SSR demo page renders the greeting from props and that
  the client-side click counter works after hydration.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "renders SSR greeting and click counter works", %{session: session} do
    session = visit(session, "/live-ssr")

    session |> find(Query.css("[data-testid='ssr-greeting']", text: "Hello from the server!"))

    count_el = session |> find(Query.css("[data-testid='click-count']"))
    assert Wallaby.Element.text(count_el) == "0"

    session = session |> click(Query.css("[data-testid='ssr-increment']"))

    count_el = session |> find(Query.css("[data-testid='click-count']"))
    assert Wallaby.Element.text(count_el) == "1"
  end
end
