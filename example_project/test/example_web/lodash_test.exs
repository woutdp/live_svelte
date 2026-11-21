defmodule ExampleWeb.LodashTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E tests for the /lodash page (PageController + Lodash Svelte component).
  """

  test "lodash page loads and shows Lodash Demo content", %{page: page} do
    Page.goto!(page, "/lodash")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Lodash Demo"))
    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Sorted with lodash"))
  end

  test "lodash page shows unordered array from LiveView props", %{page: page} do
    Page.goto!(page, "/lodash")

    el = Page.get_by_test_id(page, "lodash-unordered")
    Expect.to_contain_text!(el, "10")
    Expect.to_contain_text!(el, "50")
    Expect.to_contain_text!(el, "1")
    Expect.to_contain_text!(el, "100")
  end

  test "lodash page shows sorted array from lodash sortBy", %{page: page} do
    Page.goto!(page, "/lodash")

    el = Page.get_by_test_id(page, "lodash-ordered")
    Expect.to_contain_text!(el, "1")
    Expect.to_contain_text!(el, "100")
    Expect.to_contain_text!(el, "50")
    Expect.to_contain_text!(el, "1, 3, 10, 25, 30, 40, 50, 100")
  end
end
