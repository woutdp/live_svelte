defmodule ExampleWeb.LiveSigilTest do
  @moduledoc """
  E2E test for the LiveSigil LiveView (~V sigil).
  Validates that the page renders, server/client/combined values are correct,
  and +server / +client interactions update state and persist correctly.
  """
  use ExampleWeb.FeatureCase, async: true

  defp assert_values(page, server, client, combined) do
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-server-number"), server)
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-client-number"), client)
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-combined"), combined)
  end

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-sigil")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Svelte template (~V sigil)"))
  end

  test "renders initial server, client, and combined values", %{page: page} do
    Page.goto!(page, "/live-sigil")

    assert_values(page, "10", "5", "15")
  end

  test "clicking +server updates server number and combined", %{page: page} do
    Page.goto!(page, "/live-sigil")
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-combined"), "15")
    Locator.click!(Page.get_by_test_id(page, "sigil-increment-server"))

    assert_values(page, "11", "5", "16")
  end

  test "clicking +client updates client number and combined", %{page: page} do
    Page.goto!(page, "/live-sigil")
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-combined"), "15")
    Locator.click!(Page.get_by_test_id(page, "sigil-increment-client"))

    assert_values(page, "10", "6", "16")
  end

  test "client state persists after server increment", %{page: page} do
    Page.goto!(page, "/live-sigil")
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-combined"), "15")
    client = Page.get_by_test_id(page, "sigil-increment-client")

    Locator.click!(client)
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-client-number"), "6")
    Locator.click!(client)
    Expect.to_have_text!(Page.get_by_test_id(page, "sigil-client-number"), "7")
    Locator.click!(Page.get_by_test_id(page, "sigil-increment-server"))

    assert_values(page, "11", "7", "18")
  end
end
