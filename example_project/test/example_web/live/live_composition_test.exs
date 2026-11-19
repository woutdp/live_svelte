defmodule ExampleWeb.LiveCompositionTest do
  @moduledoc """
  E2E tests for the LiveComposition LiveView (/live-composition).
  Validates the full client→server→client loop: typing in the child TextInput
  and submitting pushes an event via useLiveSvelte(), the server prepends the
  item, and the updated list re-renders in the Svelte component.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page renders the input and submit button", %{page: page} do
    Page.goto!(page, "/live-composition")

    Expect.to_be_visible!(Page.get_by_test_id(page, "composition-input"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "composition-submit"))
  end

  test "submitting an item adds it to the list", %{page: page} do
    Page.goto!(page, "/live-composition")
    Locator.fill!(Page.get_by_test_id(page, "composition-input"), "My Widget")
    Locator.click!(Page.get_by_test_id(page, "composition-submit"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "composition-item")
      |> Locator.filter(has_text: "My Widget")
    )
  end

  test "submitting multiple items shows all of them", %{page: page} do
    Page.goto!(page, "/live-composition")
    input = Page.get_by_test_id(page, "composition-input")
    submit = Page.get_by_test_id(page, "composition-submit")

    Locator.fill!(input, "Alpha")
    Locator.click!(submit)
    Locator.fill!(input, "Beta")
    Locator.click!(submit)

    items = Page.get_by_test_id(page, "composition-item")
    Expect.to_be_visible!(Locator.filter(items, has_text: "Alpha"))
    Expect.to_be_visible!(Locator.filter(items, has_text: "Beta"))
  end

  test "empty input does not submit", %{page: page} do
    Page.goto!(page, "/live-composition")
    Locator.click!(Page.get_by_test_id(page, "composition-submit"))

    Expect.not_to_be_visible!(Page.get_by_test_id(page, "composition-item"))
  end
end
