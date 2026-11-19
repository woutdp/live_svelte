defmodule ExampleWeb.LiveNavigationTest do
  @moduledoc """
  E2E tests for the LiveNavigation LiveView (/live-navigation).
  Validates useLiveNavigation() patch/navigate and the Link component.
  """
  use ExampleWeb.FeatureCase, async: true

  defp nav_page(page), do: Page.get_by_test_id(page, "nav-page")
  defp nav_query(page), do: Page.get_by_test_id(page, "nav-query")

  test "page mounts and shows initial state", %{page: page} do
    Page.goto!(page, "/live-navigation")

    Expect.to_contain_text!(nav_page(page), "home")
    Expect.to_contain_text!(nav_query(page), "{}")
    Expect.to_be_visible!(Page.get_by_test_id(page, "patch-btn"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "navigate-btn"))
  end

  test "patch() updates query params and triggers handle_params", %{page: page} do
    Page.goto!(page, "/live-navigation")

    Expect.to_contain_text!(nav_query(page), "{}")
    Locator.click!(Page.get_by_test_id(page, "patch-btn"))
    Expect.to_contain_text!(nav_query(page), "section")
    Expect.to_contain_text!(nav_page(page), "home")
  end

  test "navigate() changes route without full page reload", %{page: page} do
    Page.goto!(page, "/live-navigation")

    Expect.to_contain_text!(nav_page(page), "home")
    Locator.click!(Page.get_by_test_id(page, "navigate-btn"))
    Expect.to_contain_text!(nav_page(page), "other")
  end

  test "Link component with patch updates URL and triggers handle_params", %{page: page} do
    Page.goto!(page, "/live-navigation")

    Expect.to_contain_text!(nav_query(page), "{}")
    Locator.click!(Page.get_by_test_id(page, "link-patch"))
    Expect.to_contain_text!(nav_query(page), "tab")
  end

  test "Link component with navigate changes route", %{page: page} do
    Page.goto!(page, "/live-navigation")

    Expect.to_contain_text!(nav_page(page), "home")
    Locator.click!(Page.get_by_test_id(page, "link-navigate"))
    Expect.to_contain_text!(nav_page(page), "linked")
  end
end
