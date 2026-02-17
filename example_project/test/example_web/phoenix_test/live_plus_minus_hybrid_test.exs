defmodule ExampleWeb.PhoenixTest.LivePlusMinusHybridTest do
  @moduledoc """
  PhoenixTest (in-process) for LivePlusMinusHybrid LiveView (/live-plus-minus-hybrid).
  Runs with SSR enabled so the CounterHybrid Svelte component is in the initial HTML.
  Validates that the page renders, initial value is 10, and plus/minus buttons are present.
  Click behavior (set_number) is covered by Wallaby E2E (live_plus_minus_hybrid_test.exs):
  click_button does not trigger phx-click on buttons inside the Svelte-rendered DOM.
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
    |> visit("/live-plus-minus-hybrid")
    |> assert_has("h2", text: "Plus / Minus (Hybrid)")
    |> assert_has("p", text: "LiveView-driven value with phx-click; step amount is client state.")
  end

  test "renders CounterHybrid Svelte component with initial props", %{conn: conn} do
    conn
    |> visit("/live-plus-minus-hybrid")
    |> assert_has("[data-name='CounterHybrid']")
    |> assert_has("[data-props*='\"number\":10']")
  end

  test "renders initial value and plus/minus buttons", %{conn: conn} do
    conn
    |> visit("/live-plus-minus-hybrid")
    |> assert_has("[data-testid='hybrid-plus-minus-value']", text: "10")
    |> assert_has("[data-testid='hybrid-plus-minus-minus']")
    |> assert_has("[data-testid='hybrid-plus-minus-plus']")
  end
end
