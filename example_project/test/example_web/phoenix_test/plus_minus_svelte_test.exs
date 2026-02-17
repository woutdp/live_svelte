defmodule ExampleWeb.PhoenixTest.PlusMinusSvelteTest do
  @moduledoc """
  PhoenixTest (in-process) for /plus-minus-svelte.
  Asserts the PlusMinus Svelte component wrapper, initial props, and that the
  value/buttons are present in the HTML by data-testid when SSR is on.
  Clicking plus/minus is not tested here: on static pages PhoenixTest's
  click_button requires the button to be inside a form (or a LiveView); our
  Svelte buttons are plain onclick with no form, so click_button raises.
  For click behavior and value updates, see Wallaby E2E (plus_minus_svelte_test.exs).
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

  test "renders the PlusMinus Svelte component wrapper with initial props", %{conn: conn} do
    conn
    |> visit("/plus-minus-svelte")
    |> assert_has("[data-name='PlusMinus']")
    |> assert_has("[data-props*='\"number\":10']")
  end

  test "renders initial value and plus/minus buttons in HTML by data-testid with SSR", %{conn: conn} do
    conn
    |> visit("/plus-minus-svelte")
    |> assert_has("[data-testid='plus-minus-value']", text: "10")
    |> assert_has("[data-testid='plus-minus-minus']")
    |> assert_has("[data-testid='plus-minus-plus']")
  end
end
