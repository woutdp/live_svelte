defmodule ExampleWeb.PhoenixTest.LiveSimpleCounterTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveSimpleCounter.
  Runs with SSR enabled and a distinct initial client value (42) so we can assert
  the client counter is bound to state, not hardcoded. If the component hardcodes
  "1" instead of using {other}, these tests fail.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest

  @moduletag :phoenix_test

  # Distinct value so we can assert client counter is reactive (fails if hardcoded "1").
  @initial_client_value 42

  setup do
    ssr = Application.get_env(:live_svelte, :ssr, false)
    initial = Application.get_env(:example, :simple_counter_initial_client_value, 1)
    Application.put_env(:live_svelte, :ssr, true)
    Application.put_env(:example, :simple_counter_initial_client_value, @initial_client_value)

    on_exit(fn ->
      Application.put_env(:live_svelte, :ssr, ssr)
      Application.put_env(:example, :simple_counter_initial_client_value, initial)
    end)

    :ok
  end

  defp assert_simple_counter_mount_points_unchanged(conn, expected_count \\ 2) do
    conn
    |> assert_has("[data-name='SimpleCounter']", count: expected_count)
  end

  defp assert_client_counter_rendered_from_state(conn) do
    conn
    |> assert_has("[data-testid='simple-counter-client-value']", text: "#{@initial_client_value}", count: 2)
  end

  test "renders page heading and description", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("h1", text: "Simple Counter Demo")
    |> assert_has("p", text: "Same LiveView state drives the native counter and both Svelte components.")
  end

  test "renders initial counter and two SimpleCounter Svelte components", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> assert_has("[data-name='SimpleCounter']", count: 2)
    |> assert_has("[data-props*='\"number\":10']", count: 2)
    |> assert_client_counter_rendered_from_state()
  end

  test "clicking +1 updates LiveView and Svelte component props", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> assert_client_counter_rendered_from_state()
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "11")
    |> assert_has("[data-props*='\"number\":11']", count: 2)
    |> assert_client_counter_rendered_from_state()
  end

  test "renders SimpleCounter components with server and client state mount points", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-name='SimpleCounter']", count: 2)
    |> assert_has("[data-props*='\"number\":10']", count: 2)
    |> assert_client_counter_rendered_from_state()
  end

  test "server increment does not remove or re-mount SimpleCounter components", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-name='SimpleCounter']", count: 2)
    |> assert_client_counter_rendered_from_state()
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "11")
    |> assert_has("[data-props*='\"number\":11']", count: 2)
    |> assert_simple_counter_mount_points_unchanged()
    |> assert_client_counter_rendered_from_state()
  end

  test "multiple consecutive server increments update only server state and props", %{conn: conn} do
    conn
    |> visit("/live-simple-counter")
    |> assert_has("[data-name='SimpleCounter']", count: 2)
    |> assert_client_counter_rendered_from_state()
    |> assert_has("[data-testid='live-simple-counter-value']", text: "10")
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "11")
    |> assert_has("[data-props*='\"number\":11']", count: 2)
    |> assert_simple_counter_mount_points_unchanged()
    |> assert_client_counter_rendered_from_state()
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "12")
    |> assert_has("[data-props*='\"number\":12']", count: 2)
    |> assert_simple_counter_mount_points_unchanged()
    |> assert_client_counter_rendered_from_state()
    |> click_button("[data-testid='live-simple-counter-increment']", "+1")
    |> assert_has("[data-testid='live-simple-counter-value']", text: "13")
    |> assert_has("[data-props*='\"number\":13']", count: 2)
    |> assert_simple_counter_mount_points_unchanged()
    |> assert_client_counter_rendered_from_state()
  end

  test "many server increments leave SimpleCounter mount points intact", %{conn: conn} do
    conn =
      conn
      |> visit("/live-simple-counter")
      |> assert_has("[data-name='SimpleCounter']", count: 2)
      |> assert_client_counter_rendered_from_state()

    # 5 server increments (10 → 15); mount points and client value must stay after each
    conn =
      Enum.reduce(1..5, conn, fn _i, acc ->
        acc
        |> click_button("[data-testid='live-simple-counter-increment']", "+1")
        |> assert_simple_counter_mount_points_unchanged()
        |> assert_client_counter_rendered_from_state()
      end)

    conn
    |> assert_has("[data-testid='live-simple-counter-value']", text: "15")
    |> assert_has("[data-props*='\"number\":15']", count: 2)
    |> assert_simple_counter_mount_points_unchanged()
    |> assert_client_counter_rendered_from_state()
  end
end
