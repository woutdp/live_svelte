defmodule ExampleWeb.LiveFormTest do
  @moduledoc """
  E2E tests for the LiveForm LiveView (/live-form).
  Validates useLiveForm() composable: initial render, server validation,
  and successful submit with form reset.
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

  test "initial form renders with inputs, no errors, and submit button", %{session: session} do
    session
    |> visit("/live-form")
    |> wait_for("form-name-input")
    |> assert_has(Query.css("[data-testid='form-name-input']"))
    |> assert_has(Query.css("[data-testid='form-email-input']"))
    |> assert_has(Query.css("[data-testid='form-submit-btn']"))
    |> refute_has(Query.css("[data-testid='form-name-error']"))
    |> refute_has(Query.css("[data-testid='form-email-error']"))
  end

  test "server validation: submitting empty form shows required errors", %{session: session} do
    session =
      session
      |> visit("/live-form")
      |> wait_for("form-submit-btn")
      |> click(Query.css("[data-testid='form-submit-btn']"))

    # Wait for server round-trip to deliver errors.
    :timer.sleep(500)

    session
    |> assert_has(Query.css("[data-testid='form-name-error']"))
    |> assert_has(Query.css("[data-testid='form-email-error']"))
  end

  test "server validation: typing invalid email shows error after debounce", %{session: session} do
    session =
      session
      |> visit("/live-form")
      |> wait_for("form-name-input")
      |> fill_in(Query.css("[data-testid='form-name-input']"), with: "Alice")
      |> fill_in(Query.css("[data-testid='form-email-input']"), with: "not-an-email")

    # Wait for debounce (300ms) + server round-trip (allow 600ms total).
    :timer.sleep(600)

    session
    |> assert_has(Query.css("[data-testid='form-email-error']"))
  end

  test "submitting valid form resets fields (re-submit verifies empty values)", %{session: session} do
    session =
      session
      |> visit("/live-form")
      |> wait_for("form-name-input")
      |> fill_in(Query.css("[data-testid='form-name-input']"), with: "Alice")
      |> fill_in(Query.css("[data-testid='form-email-input']"), with: "alice@example.com")
      |> click(Query.css("[data-testid='form-submit-btn']"))

    # Wait for first submit to complete and form to reset.
    :timer.sleep(600)

    # Submit again with now-empty fields — server should reject with validation errors.
    # This proves the form was reset (values are empty, not "Alice" / "alice@...").
    session =
      session
      |> click(Query.css("[data-testid='form-submit-btn']"))

    :timer.sleep(500)

    session
    |> assert_has(Query.css("[data-testid='form-name-error']"))
  end
end
