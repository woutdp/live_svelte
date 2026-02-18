defmodule ExampleWeb.PhoenixTest.LiveLogListTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveLogList (/live-log-list).
  Validates that the page renders the LogList Svelte component with empty items,
  and that simulating the add_item pushEvent updates props and rendered HTML.
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
    |> visit("/live-log-list")
    |> assert_has("h2", text: "Log stream")
    |> assert_has("p", text: "Add items or let the timer append entries; limit how many are shown.")
  end

  test "renders LogList mount and initial empty items in props", %{conn: conn} do
    conn
    |> visit("/live-log-list")
    |> assert_has("[data-name='LogList']")
    |> assert_has("[data-props*='\"items\":[]']")
  end

  test "simulating add_item updates LiveView state and data-props", %{conn: conn} do
    conn
    |> visit("/live-log-list")
    |> assert_has("[data-name='LogList']")
    |> assert_has("[data-props*='\"items\":[]']")
    |> assert_has("[data-testid='log-list-empty-state']")
    |> unwrap(fn view ->
      render_click(view, "add_item", %{"body" => "hello"})
    end)
    # After event, props are updated (Svelte inner HTML may not re-SSR on patch)
    |> assert_has("[data-props*='\"body\":\"hello\"']")
  end
end
