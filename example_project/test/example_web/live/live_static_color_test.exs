defmodule ExampleWeb.LiveStaticColorTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LiveStaticColor LiveView with Svelte components in a for loop.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders
  and that adding elements does not cause existing components to disappear.
  """
  @moduletag :e2e

  test "page mounts and shows the expected Svelte components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> assert_has(Query.css("h1", text: "Static Color Demo"))
      |> assert_has(Query.css("p", text: "Passing dynamic props to a list of Svelte components from LiveView."))

    # There are two Svelte grids (file-based + ~V sigil), each rendering the same color span.
    session = wait_for_svelte_count(session, 6)
    assert session |> all(Query.css("[data-testid='static-color-svelte-value']")) |> length() == 6

    # We should see two cards per index (0..2).
    for idx <- 0..2 do
      assert session |> all(Query.css("h3", text: "Svelte component #{idx}")) |> length() == 2
    end
  end

  test "adding an element increases Svelte component count and preserves all existing ones", %{session: session} do
    session = visit(session, "/live-static-color")
    session = wait_for_svelte_count(session, 6)

    session =
      session
      |> click(Query.button("Add Element"))

    # Two grids × 4 elements = 8 rendered spans
    session = wait_for_svelte_count(session, 8)
    assert session |> all(Query.css("[data-testid='static-color-svelte-value']")) |> length() == 8

    # New index shows up twice (file-based + ~V sigil)
    assert session |> all(Query.css("h3", text: "Svelte component 3")) |> length() == 2
  end

  test "clicking red button updates color in all Svelte components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> click(Query.button("Change color to red"))

    session = wait_for_svelte_count(session, 6)
    svelte_values = session |> all(Query.css("[data-testid='static-color-svelte-value']"))
    assert length(svelte_values) == 6
    for value <- svelte_values, do: assert Wallaby.Element.text(value) == "RED"
  end

  test "adding elements after color change preserves color in all components", %{session: session} do
    session =
      session
      |> visit("/live-static-color")
      |> click(Query.button("Change color to red"))
      |> click(Query.button("Add Element"))

    # Wait for the added element to mount and render across both grids (LiveView patch + client hydration)
    session = wait_for_svelte_count(session, 8)
    svelte_values = session |> all(Query.css("[data-testid='static-color-svelte-value']"))
    assert length(svelte_values) == 8
    for value <- svelte_values, do: assert Wallaby.Element.text(value) == "RED"
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
