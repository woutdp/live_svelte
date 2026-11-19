defmodule ExampleWeb.LiveStaticColorTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E test for the LiveStaticColor LiveView with Svelte components in a for loop.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders
  and that adding elements does not cause existing components to disappear.
  """

  defp svelte_values(page), do: Page.get_by_test_id(page, "static-color-svelte-value")

  test "page mounts and shows the expected Svelte components", %{page: page} do
    Page.goto!(page, "/live-static-color")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Static Color Demo"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text: "Passing dynamic props to a list of Svelte components from LiveView."
      )
    )

    Expect.to_have_count!(svelte_values(page), 6)

    for idx <- 0..2 do
      Expect.to_have_count!(Page.locator(page, "h3", has_text: "Svelte component #{idx}"), 2)
    end
  end

  test "adding an element increases Svelte component count and preserves all existing ones", %{
    page: page
  } do
    Page.goto!(page, "/live-static-color")
    Expect.to_have_count!(svelte_values(page), 6)

    Locator.click!(Page.get_by_role(page, :button, name: "Add Element"))

    Expect.to_have_count!(svelte_values(page), 8)
    Expect.to_have_count!(Page.locator(page, "h3", has_text: "Svelte component 3"), 2)
  end

  test "clicking red button updates color in all Svelte components", %{page: page} do
    Page.goto!(page, "/live-static-color")
    Locator.click!(Page.get_by_role(page, :button, name: "Change color to red"))

    Expect.to_have_count!(svelte_values(page), 6)
    # The rendered text (CSS uppercases it), as a user sees it; text_content would be "red"
    Expect.to_have_text!(svelte_values(page), List.duplicate("RED", 6), use_inner_text: true)
  end

  test "adding elements after color change preserves color in all components", %{page: page} do
    Page.goto!(page, "/live-static-color")
    Locator.click!(Page.get_by_role(page, :button, name: "Change color to red"))
    Locator.click!(Page.get_by_role(page, :button, name: "Add Element"))

    Expect.to_have_count!(svelte_values(page), 8)
    # The rendered text (CSS uppercases it), as a user sees it; text_content would be "red"
    Expect.to_have_text!(svelte_values(page), List.duplicate("RED", 8), use_inner_text: true)
  end
end
