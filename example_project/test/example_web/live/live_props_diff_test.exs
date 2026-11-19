defmodule ExampleWeb.LivePropsDiffTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E test for the LivePropsDiff LiveView: props diff demo with two Svelte components
  (diff on vs off). Validates that buttons update server state and both components
  display the same values.
  """

  defp values(page, key), do: Page.get_by_test_id(page, "props-diff-value-#{key}")

  test "page mounts and shows title", %{page: page} do
    Page.goto!(page, "/live-props-diff")

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "props-diff-page-title")
      |> Locator.filter(has_text: "Props Diff Demo")
    )
  end

  test "initial values A=1, B=2, C=3 in both cards", %{page: page} do
    Page.goto!(page, "/live-props-diff")

    Expect.to_have_text!(values(page, "a"), ["1", "1"])
    Expect.to_have_text!(values(page, "b"), ["2", "2"])
    Expect.to_have_text!(values(page, "c"), ["3", "3"])
  end

  test "Increment A updates both Svelte components to A=2", %{page: page} do
    Page.goto!(page, "/live-props-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Increment A"))

    Expect.to_have_text!(values(page, "a"), ["2", "2"])
  end

  test "Increment B then C updates displayed values", %{page: page} do
    Page.goto!(page, "/live-props-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Increment B"))
    Locator.click!(Page.get_by_role(page, :button, name: "Increment C"))

    Expect.to_have_text!(values(page, "b"), ["3", "3"])
    Expect.to_have_text!(values(page, "c"), ["4", "4"])
  end

  test "multiple increments leave all displayed values in sync", %{page: page} do
    Page.goto!(page, "/live-props-diff")
    Locator.click!(Page.get_by_role(page, :button, name: "Increment A"))
    Locator.click!(Page.get_by_role(page, :button, name: "Increment A"))
    Locator.click!(Page.get_by_role(page, :button, name: "Increment B"))

    Expect.to_have_text!(values(page, "a"), ["3", "3"])
    Expect.to_have_text!(values(page, "b"), ["3", "3"])
  end
end
