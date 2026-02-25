defmodule ExampleWeb.LiveCompositionTest do
  @moduledoc """
  E2E tests for the LiveComposition LiveView (/live-composition).
  Validates the full client→server→client loop: typing in the child TextInput
  and submitting pushes an event via useLiveSvelte(), the server prepends the
  item, and the updated list re-renders in the Svelte component.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for(session, testid, attempts \\ 30)
  defp wait_for(_session, testid, 0), do: raise("timeout waiting for [data-testid='#{testid}']")

  defp wait_for(session, testid, attempts) do
    if length(all(session, Query.css("[data-testid='#{testid}']"))) > 0 do
      session
    else
      :timer.sleep(100)
      wait_for(session, testid, attempts - 1)
    end
  end

  test "page renders the input and submit button", %{session: session} do
    session
    |> visit("/live-composition")
    |> wait_for("composition-input")
    |> assert_has(Query.css("[data-testid='composition-input']"))
    |> assert_has(Query.css("[data-testid='composition-submit']"))
  end

  test "submitting an item adds it to the list", %{session: session} do
    session
    |> visit("/live-composition")
    |> wait_for("composition-input")
    |> fill_in(Query.css("[data-testid='composition-input']"), with: "My Widget")
    |> click(Query.css("[data-testid='composition-submit']"))
    |> assert_has(Query.css("[data-testid='composition-item']", text: "My Widget"))
  end

  test "submitting multiple items shows all of them", %{session: session} do
    session
    |> visit("/live-composition")
    |> wait_for("composition-input")
    |> fill_in(Query.css("[data-testid='composition-input']"), with: "Alpha")
    |> click(Query.css("[data-testid='composition-submit']"))
    |> fill_in(Query.css("[data-testid='composition-input']"), with: "Beta")
    |> click(Query.css("[data-testid='composition-submit']"))
    |> assert_has(Query.css("[data-testid='composition-item']", text: "Alpha"))
    |> assert_has(Query.css("[data-testid='composition-item']", text: "Beta"))
  end

  test "empty input does not submit", %{session: session} do
    session
    |> visit("/live-composition")
    |> wait_for("composition-submit")
    |> click(Query.css("[data-testid='composition-submit']"))
    |> refute_has(Query.css("[data-testid='composition-item']"))
  end
end
