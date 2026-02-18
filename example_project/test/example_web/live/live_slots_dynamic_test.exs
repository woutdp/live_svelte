defmodule ExampleWeb.LiveSlotsDynamicTest do
  @moduledoc """
  E2E test for the LiveSlotsDynamic LiveView (/live-slots-dynamic).
  Validates that the page mounts with default and named slot content,
  shows initial number 1, and that clicking Increment updates the number in both slots.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page mounts and shows heading, description, slots, and initial number", %{session: session} do
    session
    |> visit("/live-slots-dynamic")
    |> assert_has(Query.css("h2", text: "Dynamic slots"))
    |> assert_has(Query.css("p", text: "Default slot and named slot (:subtitle) both receive LiveView state; the button updates the number."))

    # Slots card: badge, button, Opening/Closing, subtitle
    session |> assert_has(Query.css("[data-testid='slots-card']"))
    session |> assert_has(Query.css("[data-testid='slots-badge']", text: "Slots"))
    session |> assert_has(Query.css("[data-testid='slots-dynamic-increment']", text: "Increment the number"))
    session |> assert_has(Query.css("[data-testid='slots-opening']", text: "Opening"))
    session |> assert_has(Query.css("[data-testid='slots-closing']", text: "Closing"))
    session |> assert_has(Query.css("[data-testid='slots-subtitle']", text: "Svelte subtitle"))

    # Initial number 1 appears in default slot and in subtitle
    default_number = session |> find(Query.css("[data-testid='slots-dynamic-number']"))
    subtitle_number = session |> find(Query.css("[data-testid='slots-dynamic-subtitle-number']"))
    assert Wallaby.Element.text(default_number) == "1"
    assert Wallaby.Element.text(subtitle_number) == "1"
  end

  test "clicking Increment the number updates the number in both slots", %{session: session} do
    session =
      session
      |> visit("/live-slots-dynamic")
      |> assert_has(Query.css("[data-testid='slots-dynamic-increment']"))
      |> click(Query.css("[data-testid='slots-dynamic-increment']"))

    # Wait for both number displays to show 2
    session = wait_for_number(session, "2")
    default_number = session |> find(Query.css("[data-testid='slots-dynamic-number']"))
    subtitle_number = session |> find(Query.css("[data-testid='slots-dynamic-subtitle-number']"))
    assert Wallaby.Element.text(default_number) == "2"
    assert Wallaby.Element.text(subtitle_number) == "2"
  end

  defp wait_for_number(session, expected, attempts \\ 30) do
    default_span = session |> all(Query.css("[data-testid='slots-dynamic-number']")) |> List.first()
    actual = default_span && Wallaby.Element.text(default_span)
    cond do
      actual == expected -> session
      attempts == 0 ->
        raise "timeout waiting for number #{inspect(expected)}, got #{inspect(actual)}"
      true ->
        :timer.sleep(100)
        wait_for_number(session, expected, attempts - 1)
    end
  end
end
