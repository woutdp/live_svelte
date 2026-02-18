defmodule ExampleWeb.PhoenixTest.LiveJsonTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveJson (/live-json).
  Validates that the page renders two LiveJson sections (SSR and No SSR)
  and shows key length and Remove element button. Remove-element behavior
  is covered in E2E (live_json_test.exs).
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest

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
    |> visit("/live-json")
    |> assert_has("h2", text: "Live JSON")
    |> assert_has("p", text: "Large payloads are patched over the wire. Compare SSR vs no-SSR and watch the WebSocket traffic when removing elements.")
  end

  test "renders two sections (SSR and No SSR) with LiveJson component", %{conn: conn} do
    conn
    |> visit("/live-json")
    |> assert_has("span.badge", text: "SSR")
    |> assert_has("span.badge", text: "No SSR")
    |> assert_has("[data-name='LiveJson']", count: 2)
  end

  test "shows key length and Remove element button", %{conn: conn} do
    conn
    |> visit("/live-json")
    |> assert_has("dt", text: "Key length")
    |> assert_has("button", text: "Remove element")
  end
end
