defmodule ExampleWeb.LiveBreakingNewsTest do
  @moduledoc """
  E2E test for the LiveBreakingNews LiveView (/live-breaking-news).
  Validates that the page mounts with initial headlines, adding a headline via the UI
  works, and removing a headline removes it from the list.
  """
  use ExampleWeb.FeatureCase, async: true

  defp headline_items(page) do
    Page.locator(page, "[data-testid='breaking-news-headlines'] li")
  end

  test "page mounts and shows heading, input, and initial headlines", %{page: page} do
    Page.goto!(page, "/live-breaking-news")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Breaking News"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text: "Add headlines and control the ticker speed; remove items from the list."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "breaking-news-new-headline"))

    # Initial news has 5 items; at least one visible
    Expect.to_contain_text!(headline_items(page), ["Giant Pink Elephant"])
  end

  test "adding a headline via the UI shows it in the list and clears the input", %{page: page} do
    Page.goto!(page, "/live-breaking-news")

    input = Page.get_by_test_id(page, "breaking-news-new-headline")
    Locator.fill!(input, "Test headline")
    Locator.click!(Page.get_by_role(page, :button, name: "Add", exact: true))

    Expect.to_contain_text!(Page.get_by_test_id(page, "breaking-news-headlines"), "Test headline")
    Expect.to_have_value!(input, "")
  end

  test "removing a headline removes it from the list", %{page: page} do
    Page.goto!(page, "/live-breaking-news")

    headlines = Page.get_by_test_id(page, "breaking-news-headlines")
    Expect.to_contain_text!(headlines, "Giant Pink Elephant")
    count_before = Locator.count!(headline_items(page))

    # Click the first Remove button (first headline)
    Locator.click!(
      Locator.first(Page.locator(page, "[data-testid='breaking-news-headlines'] li button"))
    )

    # Wait for one item to disappear
    Expect.not_to_contain_text!(headlines, "Giant Pink Elephant")
    Expect.to_have_count!(headline_items(page), count_before - 1)
  end

  test "faster/slower buttons update ticker rate", %{page: page} do
    Page.goto!(page, "/live-breaking-news")

    ticker = Page.get_by_test_id(page, "breaking-news-ticker")
    Expect.to_be_visible!(ticker)
    Expect.to_have_attribute!(ticker, "data-rate", "-150")

    Locator.click!(Page.get_by_role(page, :button, name: "← Faster"))
    Expect.to_have_attribute!(ticker, "data-rate", "-170")

    Locator.click!(Page.get_by_role(page, :button, name: "Slower →"))
    Expect.to_have_attribute!(ticker, "data-rate", "-150")
  end
end
