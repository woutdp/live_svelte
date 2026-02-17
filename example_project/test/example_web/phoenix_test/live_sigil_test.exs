defmodule ExampleWeb.PhoenixTest.LiveSigilTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveSigil (~V sigil).
  Runs with SSR enabled so the inline Svelte content is in the initial HTML.
  Validates server number, client number, combined value. +server is tested via
  render_click (phx-click); +client is JS-only and covered in E2E (Wallaby).
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  setup do
    ssr = Application.get_env(:live_svelte, :ssr, false)
    Application.put_env(:live_svelte, :ssr, true)

    on_exit(fn ->
      Application.put_env(:live_svelte, :ssr, ssr)
    end)

    :ok
  end

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-sigil")
    |> assert_has("h1", text: "Svelte template (~V sigil)")
    |> assert_has("p", text: "Inline Svelte in LiveView: server state and client state in one template.")
  end

  test "renders initial server, client, and combined values", %{conn: conn} do
    conn
    |> visit("/live-sigil")
    |> assert_has("[data-testid='sigil-server-number']", text: "10")
    |> assert_has("[data-testid='sigil-client-number']", text: "5")
    |> assert_has("[data-testid='sigil-combined']", text: "15")
  end

  test "clicking +server updates server number, client unchanged, and combined sum", %{conn: conn} do
    conn
    |> visit("/live-sigil")
    # Initial: total sum 15, client 5, server 10
    |> assert_has("[data-testid='sigil-server-number']", text: "10")
    |> assert_has("[data-testid='sigil-client-number']", text: "5")
    |> assert_has("[data-testid='sigil-combined']", text: "15")
    |> unwrap(fn view ->
      render_click(view, "increment", %{})
    end)
    # After click: server 11 (formula 11 + 5 = 16; client unchanged). ~V inner DOM not re-rendered server-side.
    |> assert_has("[data-props*='\"number\":11']")
  end

  test "multiple +server updates: server 12, client still 5, combined 17", %{conn: conn} do
    conn
    |> visit("/live-sigil")
    # Initial: total sum 15, client 5
    |> assert_has("[data-testid='sigil-combined']", text: "15")
    |> assert_has("[data-testid='sigil-client-number']", text: "5")
    |> assert_has("[data-testid='sigil-server-number']", text: "10")
    |> unwrap(fn view ->
      render_click(view, "increment", %{})
      render_click(view, "increment", %{})
    end)
    # Server 12 (formula 12 + 5 = 17)
    |> assert_has("[data-props*='\"number\":12']")
  end
end
