defmodule ExampleWeb.LiveSlotsSimpleTest do
  @moduledoc """
  E2E test for the LiveSlotsSimple LiveView (/live-slots-simple).
  Validates that the page mounts and shows the Slots Svelte component
  with default slot content (Inside Slot) and card structure.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page mounts and shows heading, description, and slot content", %{session: session} do
    session
    |> visit("/live-slots-simple")
    |> assert_has(Query.css("h2", text: "Simple slots"))
    |> assert_has(Query.css("p", text: "Phoenix slots are passed into the Svelte component as the default slot content."))

    # Slots card: badge and slot content
    session |> assert_has(Query.css("[data-testid='slots-card']"))
    session |> assert_has(Query.css("[data-testid='slots-badge']", text: "Slots"))
    session |> assert_has(Query.css("[data-testid='slots-default-content']", text: "Inside Slot"))
    session |> assert_has(Query.css("[data-testid='slots-opening']", text: "Opening"))
    session |> assert_has(Query.css("[data-testid='slots-closing']", text: "Closing"))
  end
end
