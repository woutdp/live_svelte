defmodule ExampleWeb.LiveLightsTest do
  @moduledoc """
  E2E test for the LiveLights LiveView (Light Bulb Controller) with Svelte
  LightStatusBar and LightControllers. Validates that the full stack renders,
  up/down buttons update brightness, and the toggle turns the light off/on.
  """
  use ExampleWeb.FeatureCase, async: true

  defp brightness(page), do: Page.get_by_test_id(page, "light-brightness-value")

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-lights")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Light Bulb Controller"))
  end

  test "renders LightStatusBar and LightControllers with initial brightness 10%", %{page: page} do
    Page.goto!(page, "/live-lights")

    Expect.to_be_visible!(Page.locator(page, "[data-name='LightStatusBar']"))
    Expect.to_be_visible!(Page.locator(page, "[data-name='LightControllers']"))
    Expect.to_have_text!(brightness(page), "10%")
  end

  test "clicking up increases brightness", %{page: page} do
    Page.goto!(page, "/live-lights")
    Locator.click!(Page.get_by_test_id(page, "light-up"))

    Expect.to_have_text!(brightness(page), "20%")
  end

  test "clicking down decreases brightness", %{page: page} do
    Page.goto!(page, "/live-lights")
    Locator.click!(Page.get_by_test_id(page, "light-down"))

    Expect.to_have_text!(brightness(page), "OFF")
  end

  test "brightness does not go below 0", %{page: page} do
    Page.goto!(page, "/live-lights")
    Locator.click!(Page.get_by_test_id(page, "light-down"))

    Expect.to_have_text!(brightness(page), "OFF")
    Locator.click!(Page.get_by_test_id(page, "light-down"))
    Expect.to_have_text!(brightness(page), "OFF")
  end

  test "multiple up clicks increase brightness", %{page: page} do
    Page.goto!(page, "/live-lights")
    up = Page.get_by_test_id(page, "light-up")

    Locator.click!(up)
    Expect.to_have_text!(brightness(page), "20%")
    Locator.click!(up)
    Expect.to_have_text!(brightness(page), "30%")
    Locator.click!(up)
    Expect.to_have_text!(brightness(page), "40%")
  end

  test "toggle off sets brightness to OFF", %{page: page} do
    Page.goto!(page, "/live-lights")
    Locator.click!(Page.get_by_test_id(page, "light-toggle"))

    Expect.to_have_text!(brightness(page), "OFF")
  end

  test "toggle on after off restores previous brightness", %{page: page} do
    Page.goto!(page, "/live-lights")
    toggle = Page.get_by_test_id(page, "light-toggle")

    Locator.click!(toggle)
    Expect.to_have_text!(brightness(page), "OFF")
    Locator.click!(toggle)
    Expect.to_have_text!(brightness(page), "10%")
  end

  test "up then toggle off then on restores last brightness", %{page: page} do
    Page.goto!(page, "/live-lights")
    toggle = Page.get_by_test_id(page, "light-toggle")

    Locator.click!(Page.get_by_test_id(page, "light-up"))
    Expect.to_have_text!(brightness(page), "20%")
    Locator.click!(toggle)
    Expect.to_have_text!(brightness(page), "OFF")
    Locator.click!(toggle)
    Expect.to_have_text!(brightness(page), "20%")
  end
end
