defmodule ExampleWeb.LivePlusMinusTest do
  @moduledoc """
  E2E test for the LivePlusMinus LiveView (/live-plus-minus).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons
  update the value via server state. Step amount is tested by filling the input
  and triggering keyup so the LiveView receives the new amount.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_value(session, expected, attempts \\ 80) do
    if attempts == 0 do
      el = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
      actual = Wallaby.Element.text(el)
      raise "timeout waiting for value (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
    end

    el = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_value(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-plus-minus")
    |> find(Query.css("h2", text: "Plus / Minus (LiveView)"))
  end

  test "initial value is 10", %{session: session} do
    session = visit(session, "/live-plus-minus")

    value = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "clicking plus increases value", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus")
      |> click(Query.css("[data-testid='live-plus-minus-plus']"))

    session = wait_for_value(session, "11")
    value = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "11"
  end

  test "clicking minus decreases value", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus")
      |> click(Query.css("[data-testid='live-plus-minus-plus']"))

    session = wait_for_value(session, "11")
    session = session |> click(Query.css("[data-testid='live-plus-minus-minus']"))
    session = wait_for_value(session, "10")
    value = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "step amount changes increment", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus")
      |> fill_in(Query.css("input[aria-label='Step amount']"), with: "2")
      |> click(Query.css("[data-testid='live-plus-minus-plus']"))

    # Clicking the button blurs the input, so phx-blur sends "2" and server uses amount 2
    session = wait_for_value(session, "12")
    value = session |> find(Query.css("[data-testid='live-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "12"
  end
end
