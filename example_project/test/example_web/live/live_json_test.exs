defmodule ExampleWeb.LiveJsonTest do
  @moduledoc """
  E2E test for the LiveJson LiveView (/live-json).
  Validates that the page mounts with two sections (SSR and No SSR), shows key length
  and byte size, and that clicking Remove element decreases the key count.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  # First key-count dd in the first section (SSR)
  defp first_key_count_dd(session) do
    session |> all(Query.css("[data-testid='live-json-key-count']")) |> List.first()
  end

  defp wait_for_key_count(session, expected, attempts \\ 50) do
    dd = first_key_count_dd(session)
    actual = dd && Wallaby.Element.text(dd)
    cond do
      actual == expected -> session
      attempts == 0 -> raise "timeout waiting for key count #{inspect(expected)}, got #{inspect(actual)}"
      true ->
        :timer.sleep(100)
        wait_for_key_count(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading and description", %{session: session} do
    session
    |> visit("/live-json")
    |> assert_has(Query.css("h2", text: "Live JSON"))
    |> assert_has(Query.css("p", text: "Large payloads are patched over the wire. Compare SSR vs no-SSR and watch the WebSocket traffic when removing elements."))
  end

  test "renders two sections with key length and Remove element button", %{session: session} do
    session = visit(session, "/live-json")

    # Two section cards (SSR and No SSR); at least one of each badge
    ssr_badges = session |> all(Query.css("section.card span.badge", text: "SSR"))
    no_ssr_badges = session |> all(Query.css("section.card span.badge", text: "No SSR"))
    assert length(ssr_badges) >= 1
    assert length(no_ssr_badges) >= 1

    # Wait for Svelte to hydrate and show key count
    session = wait_for_key_count(session, "100,000")
    key_length_dts = session |> all(Query.css("dt", text: "Key length"))
    assert length(key_length_dts) >= 1
    remove_btns = session |> all(Query.css("[data-testid='live-json-remove-element']"))
    assert length(remove_btns) >= 1
  end

  test "clicking Remove element decreases key count", %{session: session} do
    session =
      session
      |> visit("/live-json")
      |> wait_for_key_count("100,000")

    # Click the first section's Remove element button
    [remove_btn | _] = session |> all(Query.css("[data-testid='live-json-remove-element']"))
    Wallaby.Element.click(remove_btn)

    session = wait_for_key_count(session, "99,999")
    dd = first_key_count_dd(session)
    assert Wallaby.Element.text(dd) == "99,999"
  end
end
