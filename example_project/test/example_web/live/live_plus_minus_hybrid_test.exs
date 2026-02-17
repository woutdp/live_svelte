defmodule ExampleWeb.LivePlusMinusHybridTest do
  @moduledoc """
  E2E test for the LivePlusMinusHybrid LiveView (/live-plus-minus-hybrid).
  Validates that the page mounts, shows initial value 10, and plus/minus buttons
  (phx-click set_number) update the value. Step amount is client state in Svelte;
  filling the input then clicking plus sends number+amount to the server.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_value(session, expected, attempts \\ 80) do
    if attempts == 0 do
      el = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
      actual = Wallaby.Element.text(el)
      raise "timeout waiting for value (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
    end

    el = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_value(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-plus-minus-hybrid")
    |> find(Query.css("h2", text: "Plus / Minus (Hybrid)"))
  end

  test "initial value is 10", %{session: session} do
    session = visit(session, "/live-plus-minus-hybrid")

    value = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "clicking plus increases value", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus-hybrid")
      |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))

    session = wait_for_value(session, "11")
    value = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "11"
  end

  test "clicking minus decreases value", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus-hybrid")
      |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))

    session = wait_for_value(session, "11")
    session = session |> click(Query.css("[data-testid='hybrid-plus-minus-minus']"))
    session = wait_for_value(session, "10")
    value = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "10"
  end

  test "step amount changes increment", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus-hybrid")
      |> fill_in(Query.css("[data-testid='hybrid-plus-minus-step']"), with: "2")
      |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))

    # Svelte amount is 2; button sends value 10+2=12 to LiveView
    session = wait_for_value(session, "12")
    value = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "12"
  end

  test "multiple plus clicks with stepper 2 keep stepper at 2 and increment by 2 each time", %{session: session} do
    session =
      session
      |> visit("/live-plus-minus-hybrid")
      |> fill_in(Query.css("[data-testid='hybrid-plus-minus-step']"), with: "2")

    # Click plus 3 times: 10 -> 12 -> 14 -> 16
    session = session |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))
    session = wait_for_value(session, "12")
    session = session |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))
    session = wait_for_value(session, "14")
    session = session |> click(Query.css("[data-testid='hybrid-plus-minus-plus']"))
    session = wait_for_value(session, "16")

    value = session |> find(Query.css("[data-testid='hybrid-plus-minus-value']"))
    assert Wallaby.Element.text(value) == "16"

    step_input = session |> find(Query.css("[data-testid='hybrid-plus-minus-step']"))
    assert Wallaby.Element.attr(step_input, "value") == "2"
  end
end
