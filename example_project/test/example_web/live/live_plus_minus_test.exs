defmodule ExampleWeb.LivePlusMinusTest do
  @moduledoc """
  E2E test for the LivePlusMinus LiveView (/live-plus-minus).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons
  update the value via server state. Step amount is tested by filling the input
  and triggering keyup so the LiveView receives the new amount.
  """
  use ExampleWeb.FeatureCase, async: true

  defp value(page), do: Page.get_by_test_id(page, "live-plus-minus-value")

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-plus-minus")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Plus / Minus (LiveView)"))
  end

  test "initial value is 10", %{page: page} do
    Page.goto!(page, "/live-plus-minus")

    Expect.to_have_text!(value(page), "10")
  end

  test "clicking plus increases value", %{page: page} do
    Page.goto!(page, "/live-plus-minus")
    Locator.click!(Page.get_by_test_id(page, "live-plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
  end

  test "clicking minus decreases value", %{page: page} do
    Page.goto!(page, "/live-plus-minus")
    Locator.click!(Page.get_by_test_id(page, "live-plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
    Locator.click!(Page.get_by_test_id(page, "live-plus-minus-minus"))
    Expect.to_have_text!(value(page), "10")
  end

  test "step amount changes increment", %{page: page} do
    Page.goto!(page, "/live-plus-minus")
    Locator.fill!(Page.get_by_label(page, "Step amount"), "2")
    Locator.click!(Page.get_by_test_id(page, "live-plus-minus-plus"))

    # Clicking the button blurs the input, so phx-blur sends "2" and server uses amount 2
    Expect.to_have_text!(value(page), "12")
  end
end
