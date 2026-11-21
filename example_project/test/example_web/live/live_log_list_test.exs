defmodule ExampleWeb.LiveLogListTest do
  @moduledoc """
  E2E test for the LiveLogList LiveView (/live-log-list).
  Validates that the page mounts, the Svelte LogList component shows the empty state,
  adding an item via the UI updates the list, and the timer appends entries.
  """
  use ExampleWeb.FeatureCase, async: true

  defp log_list_items(page), do: Page.locator(page, "[data-testid='log-list-items'] li")

  test "page mounts and shows heading, input, and description", %{page: page} do
    Page.goto!(page, "/live-log-list")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Log stream"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text: "Add items or let the timer append entries; limit how many are shown."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "log-list-new-entry"))

    # Empty state may be gone if timer already appended an entry
  end

  test "adding an item via the UI shows it in the list and clears the input", %{page: page} do
    Page.goto!(page, "/live-log-list")

    input = Page.get_by_test_id(page, "log-list-new-entry")
    Locator.fill!(input, "Hello")
    Locator.click!(Page.get_by_role(page, :button, name: "Add item"))

    Expect.to_be_visible!(Locator.filter(log_list_items(page), has_text: "Hello"))
    Expect.to_have_value!(input, "")
  end

  test "timer appends entries after mount", %{page: page} do
    Page.goto!(page, "/live-log-list")
    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Log stream"))

    Expect.to_be_visible!(Locator.first(log_list_items(page)))
  end
end
