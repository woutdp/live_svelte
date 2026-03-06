defmodule ExampleWeb.LiveRunedTest do
  @moduledoc """
  E2E tests for the /live-runed LiveView with the RunedDemo Svelte component.
  Validates the full pipeline: LiveView → LiveSvelte hook → Svelte mounts runed utilities.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page loads and shows heading", %{session: session} do
    session
    |> visit("/live-runed")
    |> assert_has(Query.css("h1", text: "Runed Utilities"))
  end

  test "search input renders after Svelte mounts", %{session: session} do
    session
    |> visit("/live-runed")
    |> assert_has(Query.css("[data-testid='search-input']"))
  end

  test "resizable element renders after Svelte mounts", %{session: session} do
    session
    |> visit("/live-runed")
    |> assert_has(Query.css("[data-testid='resizable-element']"))
  end

  test "pressed-keys container renders after Svelte mounts", %{session: session} do
    session
    |> visit("/live-runed")
    |> assert_has(Query.css("[data-testid='pressed-keys']"))
  end
end
