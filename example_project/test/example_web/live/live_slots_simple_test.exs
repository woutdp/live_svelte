defmodule ExampleWeb.LiveSlotsSimpleTest do
  @moduledoc """
  E2E test for the LiveSlotsSimple LiveView (/live-slots-simple).
  Validates that the page mounts and shows the Slots Svelte component
  with default slot content (Inside Slot) and card structure.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page mounts and shows heading, description, and slot content", %{page: page} do
    Page.goto!(page, "/live-slots-simple")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Simple slots"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text:
          "Phoenix slots are passed into the Svelte component as the default slot content."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "slots-card"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-badge")
      |> Locator.filter(has_text: "Slots")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-default-content")
      |> Locator.filter(has_text: "Inside Slot")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-opening")
      |> Locator.filter(has_text: "Opening")
    )

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "slots-closing")
      |> Locator.filter(has_text: "Closing")
    )
  end
end
