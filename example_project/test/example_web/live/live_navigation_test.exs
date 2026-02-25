defmodule ExampleWeb.LiveNavigationTest do
  @moduledoc """
  E2E tests for the LiveNavigation LiveView (/live-navigation).
  Validates useLiveNavigation() patch/navigate and the Link component.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page mounts and shows initial state", %{session: session} do
    session
    |> visit("/live-navigation")
    |> assert_has(Query.css("[data-testid='nav-page']", text: "home"))
    |> assert_has(Query.css("[data-testid='nav-query']", text: "{}"))
    |> assert_has(Query.css("[data-testid='patch-btn']"))
    |> assert_has(Query.css("[data-testid='navigate-btn']"))
  end

  test "patch() updates query params and triggers handle_params", %{session: session} do
    session
    |> visit("/live-navigation")
    |> assert_has(Query.css("[data-testid='nav-query']", text: "{}"))
    |> click(Query.css("[data-testid='patch-btn']"))
    |> assert_has(Query.css("[data-testid='nav-query']", text: "section"))
    |> assert_has(Query.css("[data-testid='nav-page']", text: "home"))
  end

  test "navigate() changes route without full page reload", %{session: session} do
    session
    |> visit("/live-navigation")
    |> assert_has(Query.css("[data-testid='nav-page']", text: "home"))
    |> click(Query.css("[data-testid='navigate-btn']"))
    |> assert_has(Query.css("[data-testid='nav-page']", text: "other"))
  end

  test "Link component with patch updates URL and triggers handle_params", %{session: session} do
    session
    |> visit("/live-navigation")
    |> assert_has(Query.css("[data-testid='nav-query']", text: "{}"))
    |> click(Query.css("[data-testid='link-patch']"))
    |> assert_has(Query.css("[data-testid='nav-query']", text: "tab"))
  end

  test "Link component with navigate changes route", %{session: session} do
    session
    |> visit("/live-navigation")
    |> assert_has(Query.css("[data-testid='nav-page']", text: "home"))
    |> click(Query.css("[data-testid='link-navigate']"))
    |> assert_has(Query.css("[data-testid='nav-page']", text: "linked"))
  end
end
