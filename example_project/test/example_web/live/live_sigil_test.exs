defmodule ExampleWeb.LiveSigilTest do
  @moduledoc """
  E2E test for the LiveSigil LiveView (~V sigil).
  Validates that the page renders, server/client/combined values are correct,
  and +server / +client interactions update state and persist correctly.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_sigil_value(session, testid, expected, attempts \\ 50) do
    if attempts == 0 do
      el = session |> find(Query.css("[data-testid='#{testid}']"))
      actual = Wallaby.Element.text(el)
      raise "timeout waiting for #{testid} (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
    end

    el = session |> find(Query.css("[data-testid='#{testid}']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_sigil_value(session, testid, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-sigil")
    |> find(Query.css("h1", text: "Svelte template (~V sigil)"))
  end

  test "renders initial server, client, and combined values", %{session: session} do
    session = visit(session, "/live-sigil")

    session = wait_for_sigil_value(session, "sigil-combined", "15")

    server_el = session |> find(Query.css("[data-testid='sigil-server-number']"))
    client_el = session |> find(Query.css("[data-testid='sigil-client-number']"))
    combined_el = session |> find(Query.css("[data-testid='sigil-combined']"))

    assert Wallaby.Element.text(server_el) == "10"
    assert Wallaby.Element.text(client_el) == "5"
    assert Wallaby.Element.text(combined_el) == "15"
  end

  test "clicking +server updates server number and combined", %{session: session} do
    session =
      session
      |> visit("/live-sigil")
      |> wait_for_sigil_value("sigil-combined", "15")
      |> click(Query.css("[data-testid='sigil-increment-server']"))

    session = wait_for_sigil_value(session, "sigil-combined", "16")

    server_el = session |> find(Query.css("[data-testid='sigil-server-number']"))
    client_el = session |> find(Query.css("[data-testid='sigil-client-number']"))
    combined_el = session |> find(Query.css("[data-testid='sigil-combined']"))

    assert Wallaby.Element.text(server_el) == "11"
    assert Wallaby.Element.text(client_el) == "5"
    assert Wallaby.Element.text(combined_el) == "16"
  end

  test "clicking +client updates client number and combined", %{session: session} do
    session =
      session
      |> visit("/live-sigil")
      |> wait_for_sigil_value("sigil-combined", "15")
      |> click(Query.css("[data-testid='sigil-increment-client']"))

    session = wait_for_sigil_value(session, "sigil-combined", "16")

    server_el = session |> find(Query.css("[data-testid='sigil-server-number']"))
    client_el = session |> find(Query.css("[data-testid='sigil-client-number']"))
    combined_el = session |> find(Query.css("[data-testid='sigil-combined']"))

    assert Wallaby.Element.text(server_el) == "10"
    assert Wallaby.Element.text(client_el) == "6"
    assert Wallaby.Element.text(combined_el) == "16"
  end

  test "client state persists after server increment", %{session: session} do
    session =
      session
      |> visit("/live-sigil")
      |> wait_for_sigil_value("sigil-combined", "15")
      |> click(Query.css("[data-testid='sigil-increment-client']"))

    session = wait_for_sigil_value(session, "sigil-client-number", "6")
    session = session |> click(Query.css("[data-testid='sigil-increment-client']"))
    session = wait_for_sigil_value(session, "sigil-client-number", "7")

    # Now server increment: server 10 -> 11, client should stay 7, combined 18
    session = session |> click(Query.css("[data-testid='sigil-increment-server']"))
    session = wait_for_sigil_value(session, "sigil-combined", "18")

    server_el = session |> find(Query.css("[data-testid='sigil-server-number']"))
    client_el = session |> find(Query.css("[data-testid='sigil-client-number']"))
    combined_el = session |> find(Query.css("[data-testid='sigil-combined']"))

    assert Wallaby.Element.text(server_el) == "11"
    assert Wallaby.Element.text(client_el) == "7"
    assert Wallaby.Element.text(combined_el) == "18"
  end
end
