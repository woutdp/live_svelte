defmodule ExampleWeb.PlusMinusSvelteTest do
  @moduledoc """
  E2E test for the /plus-minus-svelte page (PageController + PlusMinus Svelte component).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons update the value.
  """
  use ExampleWeb.FeatureCase, async: true

  defp value(page), do: Page.get_by_test_id(page, "plus-minus-value")

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/plus-minus-svelte")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Plus / Minus"))
  end

  test "initial value is 10", %{page: page} do
    Page.goto!(page, "/plus-minus-svelte")

    Expect.to_have_text!(value(page), "10")
  end

  test "clicking plus increases value", %{page: page} do
    Page.goto!(page, "/plus-minus-svelte")
    Locator.click!(Page.get_by_test_id(page, "plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
  end

  test "clicking minus decreases value", %{page: page} do
    Page.goto!(page, "/plus-minus-svelte")
    Locator.click!(Page.get_by_test_id(page, "plus-minus-plus"))

    Expect.to_have_text!(value(page), "11")
    Locator.click!(Page.get_by_test_id(page, "plus-minus-minus"))
    Expect.to_have_text!(value(page), "10")
  end

  test "step amount changes increment", %{page: page} do
    Page.goto!(page, "/plus-minus-svelte")
    Locator.fill!(Page.get_by_label(page, "Step amount"), "2")
    Locator.click!(Page.get_by_test_id(page, "plus-minus-plus"))

    Expect.to_have_text!(value(page), "12")
  end
end
