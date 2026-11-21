defmodule ExampleWeb.LivePlusMinusHybridTest do
  @moduledoc """
  E2E test for the LivePlusMinusHybrid LiveView (/live-plus-minus-hybrid).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons
  (phx-click set_number) update the value. Step amount is client state in Svelte;
  filling the input then clicking plus sends number+amount to the server.
  """
  use ExampleWeb.FeatureCase, async: true

  defp value(page), do: Page.get_by_test_id(page, "hybrid-plus-minus-value")

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-plus-minus-hybrid")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Plus / Minus (Hybrid)"))
  end

  test "initial value is 10", %{page: page} do
    Page.goto!(page, "/live-plus-minus-hybrid")

    Expect.to_have_text!(value(page), "10")
  end

  test "clicking plus increases value", %{page: page} do
    Page.goto!(page, "/live-plus-minus-hybrid")
    Locator.click!(Page.get_by_test_id(page, "hybrid-plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
  end

  test "clicking minus decreases value", %{page: page} do
    Page.goto!(page, "/live-plus-minus-hybrid")
    Locator.click!(Page.get_by_test_id(page, "hybrid-plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
    Locator.click!(Page.get_by_test_id(page, "hybrid-plus-minus-minus"))
    Expect.to_have_text!(value(page), "10")
  end

  test "step amount changes increment", %{page: page} do
    Page.goto!(page, "/live-plus-minus-hybrid")
    Locator.fill!(Page.get_by_test_id(page, "hybrid-plus-minus-step"), "2")
    Locator.click!(Page.get_by_test_id(page, "hybrid-plus-minus-plus"))

    # Svelte amount is 2; button sends value 10+2=12 to LiveView
    Expect.to_have_text!(value(page), "12")
  end

  test "multiple plus clicks with stepper 2 keep stepper at 2 and increment by 2 each time", %{
    page: page
  } do
    Page.goto!(page, "/live-plus-minus-hybrid")
    step = Page.get_by_test_id(page, "hybrid-plus-minus-step")
    plus = Page.get_by_test_id(page, "hybrid-plus-minus-plus")
    Locator.fill!(step, "2")

    # Click plus 3 times: 10 -> 12 -> 14 -> 16
    Locator.click!(plus)
    Expect.to_have_text!(value(page), "12")
    Locator.click!(plus)
    Expect.to_have_text!(value(page), "14")
    Locator.click!(plus)
    Expect.to_have_text!(value(page), "16")

    Expect.to_have_value!(step, "2")
  end
end
