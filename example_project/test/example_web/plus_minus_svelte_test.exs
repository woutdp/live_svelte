defmodule ExampleWeb.PlusMinusSvelteTest do
  @moduledoc """
  E2E test for the /plus-minus-svelte page (PageController + PlusMinus Svelte component).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons update the value.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_value(session, expected, attempts \\ 80) do
    if attempts == 0 do
      el = session |> find(Query.css("[data-testid='plus-minus-value']"))
      actual = Wallaby.Element.text(el)
      raise "timeout waiting for value (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
    end

    el = session |> find(Query.css("[data-testid='plus-minus-value']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_value(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/plus-minus-svelte")
    |> find(Query.css("h2", text: "Plus / Minus"))
  end

  test "initial value is 10", %{session: session} do
    session = visit(session, "/plus-minus-svelte")

    value = session |> find(Query.css("[data-testid='plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "clicking plus increases value", %{session: session} do
    session =
      session
      |> visit("/plus-minus-svelte")
      |> click(Query.css("[data-testid='plus-minus-plus']"))

    session = wait_for_value(session, "11")
    value = session |> find(Query.css("[data-testid='plus-minus-value']"))
    assert Wallaby.Element.text(value) == "11"
  end

  test "clicking minus decreases value", %{session: session} do
    session =
      session
      |> visit("/plus-minus-svelte")
      |> click(Query.css("[data-testid='plus-minus-plus']"))

    session = wait_for_value(session, "11")
    session = session |> click(Query.css("[data-testid='plus-minus-minus']"))
    session = wait_for_value(session, "10")
    value = session |> find(Query.css("[data-testid='plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "step amount changes increment", %{session: session} do
    session =
      session
      |> visit("/plus-minus-svelte")
      |> fill_in(Query.css("input[aria-label='Step amount']"), with: "2")
      |> click(Query.css("[data-testid='plus-minus-plus']"))

    session = wait_for_value(session, "12")
    value = session |> find(Query.css("[data-testid='plus-minus-value']"))
    assert Wallaby.Element.text(value) == "12"
  end
end
