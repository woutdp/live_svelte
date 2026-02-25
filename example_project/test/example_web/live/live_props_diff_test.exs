defmodule ExampleWeb.LivePropsDiffTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LivePropsDiff LiveView: props diff demo with two Svelte components
  (diff on vs off). Validates that buttons update server state and both components
  display the same values.
  """
  @moduletag :e2e

  test "page mounts and shows title", %{session: session} do
    session
    |> visit("/live-props-diff")
    |> find(Query.css("[data-testid='props-diff-page-title']", text: "Props Diff Demo"))
  end

  test "initial values A=1, B=2, C=3 in both cards", %{session: session} do
    session = visit(session, "/live-props-diff")

    values_a = session |> all(Query.css("[data-testid='props-diff-value-a']"))
    values_b = session |> all(Query.css("[data-testid='props-diff-value-b']"))
    values_c = session |> all(Query.css("[data-testid='props-diff-value-c']"))

    assert length(values_a) == 2
    assert length(values_b) == 2
    assert length(values_c) == 2

    for el <- values_a, do: assert(Wallaby.Element.text(el) == "1")
    for el <- values_b, do: assert(Wallaby.Element.text(el) == "2")
    for el <- values_c, do: assert(Wallaby.Element.text(el) == "3")
  end

  test "Increment A updates both Svelte components to A=2", %{session: session} do
    session =
      session
      |> visit("/live-props-diff")
      |> click(Query.button("Increment A"))

    values_a = session |> all(Query.css("[data-testid='props-diff-value-a']"))
    assert length(values_a) == 2
    for el <- values_a, do: assert(Wallaby.Element.text(el) == "2")
  end

  test "Increment B then C updates displayed values", %{session: session} do
    session =
      session
      |> visit("/live-props-diff")
      |> click(Query.button("Increment B"))
      |> click(Query.button("Increment C"))

    values_b = session |> all(Query.css("[data-testid='props-diff-value-b']"))
    values_c = session |> all(Query.css("[data-testid='props-diff-value-c']"))
    assert length(values_b) == 2
    assert length(values_c) == 2
    for el <- values_b, do: assert(Wallaby.Element.text(el) == "3")
    for el <- values_c, do: assert(Wallaby.Element.text(el) == "4")
  end

  test "multiple increments leave all displayed values in sync", %{session: session} do
    session =
      session
      |> visit("/live-props-diff")
      |> click(Query.button("Increment A"))
      |> click(Query.button("Increment A"))
      |> click(Query.button("Increment B"))

    values_a = session |> all(Query.css("[data-testid='props-diff-value-a']"))
    values_b = session |> all(Query.css("[data-testid='props-diff-value-b']"))
    for el <- values_a, do: assert(Wallaby.Element.text(el) == "3")
    for el <- values_b, do: assert(Wallaby.Element.text(el) == "3")
  end
end
