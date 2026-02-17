defmodule ExampleWeb.LiveLightsTest do
  @moduledoc """
  E2E test for the LiveLights LiveView (Light Bulb Controller) with Svelte
  LightStatusBar and LightControllers. Validates that the full stack renders,
  up/down buttons update brightness, and the toggle turns the light off/on.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_brightness(session, expected, attempts \\ 80) do
    if attempts == 0 do
      el = session |> find(Query.css("[data-testid='light-brightness-value']"))
      actual = Wallaby.Element.text(el)
      raise "timeout waiting for brightness (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
    end

    el = session |> find(Query.css("[data-testid='light-brightness-value']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_brightness(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-lights")
    |> find(Query.css("h1", text: "Light Bulb Controller"))
  end

  test "renders LightStatusBar and LightControllers with initial brightness 10%", %{session: session} do
    session = visit(session, "/live-lights")

    session |> find(Query.css("[data-name='LightStatusBar']"))
    session |> find(Query.css("[data-name='LightControllers']"))

    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "10%"
  end

  test "clicking up increases brightness", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-up']"))

    session = wait_for_brightness(session, "20%")
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "20%"
  end

  test "clicking down decreases brightness", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-down']"))

    session = wait_for_brightness(session, "OFF")
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "OFF"
  end

  test "brightness does not go below 0", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-down']"))

    session = wait_for_brightness(session, "OFF")
    session = session |> click(Query.css("[data-testid='light-down']"))
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "OFF"
  end

  test "multiple up clicks increase brightness", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-up']"))

    session = wait_for_brightness(session, "20%")
    session = session |> click(Query.css("[data-testid='light-up']"))
    session = wait_for_brightness(session, "30%")
    session = session |> click(Query.css("[data-testid='light-up']"))
    session = wait_for_brightness(session, "40%")

    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "40%"
  end

  test "toggle off sets brightness to OFF", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-toggle']"))

    session = wait_for_brightness(session, "OFF")
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "OFF"
  end

  test "toggle on after off restores previous brightness", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-toggle']"))

    session = wait_for_brightness(session, "OFF")
    session = session |> click(Query.css("[data-testid='light-toggle']"))
    session = wait_for_brightness(session, "10%")
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "10%"
  end

  test "up then toggle off then on restores last brightness", %{session: session} do
    session =
      session
      |> visit("/live-lights")
      |> click(Query.css("[data-testid='light-up']"))

    session = wait_for_brightness(session, "20%")
    session = session |> click(Query.css("[data-testid='light-toggle']"))
    session = wait_for_brightness(session, "OFF")
    session = session |> click(Query.css("[data-testid='light-toggle']"))
    session = wait_for_brightness(session, "20%")
    value = session |> find(Query.css("[data-testid='light-brightness-value']"))
    assert Wallaby.Element.text(value) == "20%"
  end
end
