defmodule ExampleWeb.LiveStaticColorTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LiveStaticColor LiveView with Svelte components in a for loop.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders
  and that adding elements does not cause existing components to disappear.
  """
  @moduletag :e2e

  test "page mounts and shows three Svelte components", %{session: session} do
    session
    |> visit("/live-static-color")
    |> find(Query.css("h2", text: "Static color"))

    # Three Svelte "Static" components rendered inside the for loop
    svelte_components = session |> all(Query.css("[data-name='Static']"))
    assert length(svelte_components) == 3

    # Each shows the Svelte-rendered content
    svelte_headings = session |> all(Query.css("h3", text: "Svelte component"))
    assert length(svelte_headings) == 3
  end

  test "adding an element increases Svelte component count and preserves all existing ones", %{session: session} do
    session = visit(session, "/live-static-color")

    svelte_query = Query.css("[data-name='Static']")
    initial_count = session |> all(svelte_query) |> length()
    assert initial_count == 3

    session
    |> click(Query.css("[data-testid='static-color-add-element']"))

    # All original components must still be present, plus the new one
    new_count = session |> all(svelte_query) |> length()
    assert new_count == initial_count + 1, "expected #{initial_count + 1} Svelte components, got #{new_count}"

    # Verify all Svelte components are actually rendering (not just empty hook divs)
    svelte_headings = session |> all(Query.css("h3", text: "Svelte component"))
    assert length(svelte_headings) == new_count
  end

  test "clicking red button updates color in all Svelte components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> click(Query.button("Change color to red"))

    # All Svelte components receive the updated color
    svelte_values = session |> all(Query.css("[data-testid='static-color-svelte-value']"))
    assert length(svelte_values) == 3
    for value <- svelte_values, do: assert Wallaby.Element.text(value) == "red"
  end

  test "clicking blue button updates color in all Svelte components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> click(Query.button("Change color to blue"))

    # All Svelte components receive the updated color
    svelte_values = session |> all(Query.css("[data-testid='static-color-svelte-value']"))
    assert length(svelte_values) == 3
    for value <- svelte_values, do: assert Wallaby.Element.text(value) == "blue"
  end

  test "adding elements after color change preserves color in all components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> click(Query.button("Change color to red"))
      |> click(Query.css("[data-testid='static-color-add-element']"))

    # Wait for the 4th Svelte component to mount and render (LiveView patch + client hydration)
    session = wait_for_svelte_count(session, 4)
    svelte_values = session |> all(Query.css("[data-testid='static-color-svelte-value']"))
    assert length(svelte_values) == 4
    for value <- svelte_values, do: assert Wallaby.Element.text(value) == "red"
  end

  defp wait_for_svelte_count(session, expected, attempts \\ 80) do
    count = session |> all(Query.css("[data-testid='static-color-svelte-value']")) |> length()
    cond do
      count >= expected -> session
      attempts == 0 -> raise "timeout waiting for #{expected} Svelte value elements, got #{count}"
      true ->
        :timer.sleep(100)
        wait_for_svelte_count(session, expected, attempts - 1)
    end
  end
end
