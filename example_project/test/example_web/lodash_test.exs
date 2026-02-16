defmodule ExampleWeb.LodashTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E tests for the /lodash page (PageController + Lodash Svelte component).
  """
  @moduletag :e2e

  test "lodash page loads and shows Lodash Demo content", %{session: session} do
    session = visit(session, "/lodash")

    session |> find(Query.css("h1", text: "Lodash Demo"))
    session |> find(Query.css("h2", text: "Sorted with lodash"))
  end

  test "lodash page shows unordered array from LiveView props", %{session: session} do
    session = visit(session, "/lodash")

    # Props are %{unordered: [10, 50, 25, 1, 3, 100, 40, 30]}
    el = session |> find(Query.css("[data-testid='lodash-unordered']"))
    assert Wallaby.Element.text(el) =~ "10"
    assert Wallaby.Element.text(el) =~ "50"
    assert Wallaby.Element.text(el) =~ "1"
    assert Wallaby.Element.text(el) =~ "100"
  end

  test "lodash page shows sorted array from lodash sortBy", %{session: session} do
    session = visit(session, "/lodash")

    # Sorted: 1, 3, 10, 25, 30, 40, 50, 100
    el = session |> find(Query.css("[data-testid='lodash-ordered']"))
    text = Wallaby.Element.text(el)
    assert text =~ "1"
    assert text =~ "100"
    assert text =~ "50"
    # Order matters: 1 should appear before 10, 10 before 25, etc.
    assert text =~ "1, 3, 10, 25, 30, 40, 50, 100"
  end
end
