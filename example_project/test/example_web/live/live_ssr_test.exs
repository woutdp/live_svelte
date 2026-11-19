defmodule ExampleWeb.Live.LiveSsrTest do
  @moduledoc """
  E2E test for the LiveSsr LiveView (/live-ssr).
  Validates that the SSR demo page renders the greeting from props and that
  the client-side click counter works after hydration.
  """
  use ExampleWeb.FeatureCase, async: true

  test "renders SSR greeting and click counter works", %{page: page} do
    Page.goto!(page, "/live-ssr")

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "ssr-greeting")
      |> Locator.filter(has_text: "Hello from the server!")
    )

    count = Page.get_by_test_id(page, "click-count")
    Expect.to_have_text!(count, "0")

    Locator.click!(Page.get_by_test_id(page, "ssr-increment"))
    Expect.to_have_text!(count, "1")
  end
end
