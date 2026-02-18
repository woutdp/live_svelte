defmodule ExampleWeb.PhoenixTest.LiveClientSideLoadingTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveClientSideLoading (/live-client-side-loading).
  Validates that the page renders heading, description, two section cards with loading slots,
  and two ClientSideLoading mount points. Uses default test config (ssr: false) so both
  components show loading in initial HTML.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest

  @moduletag :phoenix_test

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-client-side-loading")
    |> assert_has("[data-testid='client-side-loading-heading']", text: "Client-side loading")
    |> assert_has("p", text: "Use the loading slot when SSR is disabled; the slot shows until the component hydrates on the client.")
  end

  test "renders two ClientSideLoading mount points", %{conn: conn} do
    conn
    |> visit("/live-client-side-loading")
    |> assert_has("[data-name='ClientSideLoading']", count: 2)
  end

  test "renders loading state in initial HTML", %{conn: conn} do
    conn
    |> visit("/live-client-side-loading")
    |> assert_has("span", text: "Loading…")
  end

  test "renders both section cards with badges", %{conn: conn} do
    conn
    |> visit("/live-client-side-loading")
    |> assert_has("[data-testid='client-side-loading-client-section']")
    |> assert_has("[data-testid='client-side-loading-server-section']")
    |> assert_has("span.badge", text: "Client side")
    |> assert_has("span.badge", text: "Server side (avoid)")
  end
end
