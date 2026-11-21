defmodule ExampleWeb.LiveStructTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E tests for the /live-struct LiveView (Struct Svelte component with struct props).
  """

  test "live-struct page loads and shows Struct Demo", %{page: page} do
    Page.goto!(page, "/live-struct")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Struct Demo"))
    Expect.to_be_visible!(Page.locator(page, "p", has_text: "Passing a struct to Svelte."))
  end

  test "struct data flows from LiveView to Svelte component and updates on server events", %{
    page: page
  } do
    Page.goto!(page, "/live-struct")

    json = Page.get_by_test_id(page, "struct-json")
    Expect.to_contain_text!(json, "Bob")
    Expect.to_contain_text!(json, "42")

    Locator.click!(Page.get_by_test_id(page, "struct-randomize-age"))
    Expect.not_to_contain_text!(json, "42")
  end
end
