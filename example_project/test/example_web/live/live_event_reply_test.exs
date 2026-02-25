defmodule ExampleWeb.LiveEventReplyTest do
  @moduledoc """
  E2E tests for the LiveEventReply LiveView (/live-event-reply).
  Validates useEventReply() composable: initial render and request-response flow.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Wait for an element with the given testid to appear (retries up to 3s).
  defp wait_for(session, testid, attempts \\ 30)
  defp wait_for(_session, testid, 0), do: raise("timeout waiting for [data-testid='#{testid}']")

  defp wait_for(session, testid, attempts) do
    els = session |> all(Query.css("[data-testid='#{testid}']"))

    if length(els) > 0 do
      session
    else
      :timer.sleep(100)
      wait_for(session, testid, attempts - 1)
    end
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "initial render shows compute button with no result", %{session: session} do
    session
    |> visit("/live-event-reply")
    |> wait_for("compute-btn")
    |> assert_has(Query.css("[data-testid='compute-btn']"))
    |> refute_has(Query.css("[data-testid='reply-result']"))
  end

  test "clicking compute shows result from Phoenix reply", %{session: session} do
    session
    |> visit("/live-event-reply")
    |> wait_for("compute-btn")
    |> click(Query.css("[data-testid='compute-btn']"))
    |> wait_for("reply-result")
    |> assert_has(Query.css("[data-testid='result-value']"))
  end
end
