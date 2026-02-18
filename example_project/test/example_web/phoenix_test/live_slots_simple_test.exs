defmodule ExampleWeb.PhoenixTest.LiveSlotsSimpleTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveSlotsSimple (/live-slots-simple).
  Validates that the page renders the Slots Svelte component with default slot content.
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
    |> visit("/live-slots-simple")
    |> assert_has("h2", text: "Simple slots")
    |> assert_has("p", text: "Phoenix slots are passed into the Svelte component as the default slot content.")
  end

  test "renders Slots component with default slot content", %{conn: conn} do
    conn
    |> visit("/live-slots-simple")
    |> assert_has("[data-name='Slots']")
    |> assert_has("span.badge", text: "Slots")
    |> assert_has("div", text: "Inside Slot")
    |> assert_has("div", text: "Opening")
    |> assert_has("div", text: "Closing")
  end
end
