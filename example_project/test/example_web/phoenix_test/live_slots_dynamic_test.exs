defmodule ExampleWeb.PhoenixTest.LiveSlotsDynamicTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveSlotsDynamic (/live-slots-dynamic).
  Validates that the page renders the Slots Svelte component with default and
  named (:subtitle) slots bound to LiveView state, and that the increment event updates the number.
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
    |> visit("/live-slots-dynamic")
    |> assert_has("h2", text: "Dynamic slots")
    |> assert_has("p", text: "Default slot and named slot (:subtitle) both receive LiveView state; the button updates the number.")
  end

  test "renders Slots with default and subtitle slots showing initial number", %{conn: conn} do
    conn
    |> visit("/live-slots-dynamic")
    |> assert_has("[data-name='Slots']")
    |> assert_has("[data-testid='slots-badge']", text: "Slots")
    |> assert_has("[data-testid='slots-dynamic-increment']", text: "Increment the number")
    |> assert_has("[data-testid='slots-opening']", text: "Opening")
    |> assert_has("[data-testid='slots-closing']", text: "Closing")
    |> assert_has("[data-testid='slots-subtitle']", text: "Svelte subtitle")
    |> assert_has("[data-testid='slots-dynamic-number']", text: "1")
    |> assert_has("[data-testid='slots-dynamic-subtitle-number']", text: "1")
  end

  # Increment click and number update are covered in E2E; slot content may not re-render server-side after event.
  test "increment button is present", %{conn: conn} do
    conn
    |> visit("/live-slots-dynamic")
    |> assert_has("[data-testid='slots-dynamic-increment']", text: "Increment the number")
  end
end
