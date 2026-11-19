defmodule ExampleWeb.LiveStoresTest do
  @moduledoc """
  E2E tests for the /live-stores LiveView with the StoreCounter Svelte component.
  The key assertion: both component instances share the same writable store —
  incrementing in one card immediately updates the other.
  """
  use ExampleWeb.FeatureCase, async: true

  defp counts(page), do: Page.get_by_test_id(page, "store-count")

  test "page loads and shows heading", %{page: page} do
    Page.goto!(page, "/live-stores")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Svelte Stores"))
  end

  test "both StoreCounter instances render", %{page: page} do
    Page.goto!(page, "/live-stores")

    Expect.to_be_visible!(Page.get_by_test_id(page, "store-instance-1"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "store-instance-2"))
  end

  test "both instances show initial count of 0", %{page: page} do
    Page.goto!(page, "/live-stores")

    Expect.to_have_text!(counts(page), ["0", "0"])
  end

  test "incrementing in instance 1 updates both components (store is shared)", %{page: page} do
    Page.goto!(page, "/live-stores")
    Expect.to_have_count!(counts(page), 2)

    instance1 = Page.get_by_test_id(page, "store-instance-1")
    Locator.click!(Locator.get_by_test_id(instance1, "store-increment"))

    Expect.to_have_text!(counts(page), ["1", "1"])
  end

  test "reset button sets store back to 0 in both components", %{page: page} do
    Page.goto!(page, "/live-stores")
    Expect.to_have_count!(counts(page), 2)

    instance2 = Page.get_by_test_id(page, "store-instance-2")
    Locator.click!(Locator.get_by_test_id(instance2, "store-increment"))
    Expect.to_have_text!(counts(page), ["1", "1"])

    instance1 = Page.get_by_test_id(page, "store-instance-1")
    Locator.click!(Locator.get_by_test_id(instance1, "store-reset"))

    Expect.to_have_text!(counts(page), ["0", "0"])
  end
end
