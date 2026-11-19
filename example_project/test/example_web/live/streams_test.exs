defmodule ExampleWeb.StreamsTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E tests for the Streams LiveView: verifies that Phoenix stream items are rendered
  correctly in the Svelte StreamDemo component with insert, delete, and reset behavior.
  """

  defp item(page, n), do: Page.get_by_test_id(page, "item-#{n}")
  defp item_name(page, n), do: Page.get_by_test_id(page, "item-name-#{n}")
  defp item_names(page), do: Page.locator(page, "[data-testid^='item-name-']")

  test "renders initial 3 stream items", %{page: page} do
    Page.goto!(page, "/streams")

    for n <- 1..3 do
      Expect.to_be_visible!(item(page, n))
      Expect.to_be_visible!(Locator.filter(item_name(page, n), has_text: "Item #{n}"))
    end
  end

  test "adds new item to stream", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.fill!(Page.get_by_test_id(page, "name-input"), "New Item")
    Locator.fill!(Page.get_by_test_id(page, "description-input"), "A new description")
    Locator.click!(Page.get_by_test_id(page, "add-button"))

    Expect.to_be_visible!(item(page, 4))
    Expect.to_be_visible!(Locator.filter(item_name(page, 4), has_text: "New Item"))
  end

  test "removes item from stream", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "remove-2"))

    Expect.to_be_visible!(item(page, 1))
    Expect.to_be_visible!(item(page, 3))
    Expect.to_have_count!(item(page, 2), 0)
  end

  test "clears entire stream", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "clear-button"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "empty-message")
      |> Locator.filter(has_text: "No items in the stream")
    )

    Expect.to_have_count!(item(page, 1), 0)
  end

  test "resets stream with at: -1 restores items in append order", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "clear-button"))
    Locator.click!(Page.get_by_test_id(page, "reset-button"))

    Expect.to_be_visible!(item(page, 1))
    Expect.to_be_visible!(item(page, 2))
    Expect.to_be_visible!(item(page, 3))
    Expect.to_have_count!(Page.get_by_test_id(page, "empty-message"), 0)

    Expect.to_have_text!(item_names(page), ["Item 1", "Item 2", "Item 3"])
  end

  test "resets stream with at: 0 restores items in prepend order", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "clear-button"))
    Locator.click!(Page.get_by_test_id(page, "reset-button-at-0"))

    Expect.to_have_text!(item_names(page), ["Item 3", "Item 2", "Item 1"])
  end

  test "updating existing item updates in place without duplication (AC7)", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "update-1"))

    Expect.to_be_visible!(item(page, 1))
    Expect.to_be_visible!(item(page, 2))
    Expect.to_be_visible!(item(page, 3))
    Expect.to_be_visible!(Locator.filter(item_name(page, 1), has_text: "Updated 1"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "item-count")
      |> Locator.filter(has_text: "Items (3)")
    )
  end

  test "stream limit enforced: capped insert keeps only last 3 items", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.click!(Page.get_by_test_id(page, "add-capped-button"))

    Expect.to_be_visible!(item(page, 2))
    Expect.to_be_visible!(item(page, 3))
    Expect.to_be_visible!(item(page, 4))
    Expect.to_have_count!(item(page, 1), 0)

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "item-count")
      |> Locator.filter(has_text: "Items (3)")
    )
  end

  test "sequential add and remove maintains correct state", %{page: page} do
    Page.goto!(page, "/streams")
    Locator.fill!(Page.get_by_test_id(page, "name-input"), "Item 4")
    Locator.fill!(Page.get_by_test_id(page, "description-input"), "Fourth")
    Locator.click!(Page.get_by_test_id(page, "add-button"))
    Locator.click!(Page.get_by_test_id(page, "remove-2"))

    Expect.to_be_visible!(item(page, 1))
    Expect.to_be_visible!(item(page, 3))
    Expect.to_be_visible!(item(page, 4))
    Expect.to_have_count!(item(page, 2), 0)
  end
end
