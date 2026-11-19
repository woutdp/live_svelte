defmodule ExampleWeb.LiveSlotsDynamicTest do
  @moduledoc """
  E2E test for the LiveSlotsDynamic LiveView (/live-slots-dynamic).
  Validates that the page mounts with default and named slot content,
  shows initial number 1, and that clicking Increment updates the number in both slots.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page mounts and shows heading, description, slots, and initial number", %{page: page} do
    Page.goto!(page, "/live-slots-dynamic")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Dynamic slots"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text:
          "Default slot and named slot (:subtitle) both receive LiveView state; the button updates the number."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "slots-card"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-badge")
      |> Locator.filter(has_text: "Slots")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-dynamic-increment")
      |> Locator.filter(has_text: "Increment the number")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-opening")
      |> Locator.filter(has_text: "Opening")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-closing")
      |> Locator.filter(has_text: "Closing")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-subtitle")
      |> Locator.filter(has_text: "Svelte subtitle")
    )

    Expect.to_have_text!(Page.get_by_test_id(page, "slots-dynamic-number"), "1")
    Expect.to_have_text!(Page.get_by_test_id(page, "slots-dynamic-subtitle-number"), "1")
  end

  test "clicking Increment the number updates the number in both slots", %{page: page} do
    Page.goto!(page, "/live-slots-dynamic")
    increment = Page.get_by_test_id(page, "slots-dynamic-increment")
    Expect.to_be_visible!(increment)
    Locator.click!(increment)

    Expect.to_have_text!(Page.get_by_test_id(page, "slots-dynamic-number"), "2")
    Expect.to_have_text!(Page.get_by_test_id(page, "slots-dynamic-subtitle-number"), "2")
  end
end
