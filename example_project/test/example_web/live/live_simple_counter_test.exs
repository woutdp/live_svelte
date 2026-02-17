defmodule ExampleWeb.LiveSimpleCounterTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LiveSimpleCounter LiveView with Svelte SimpleCounter components.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders,
  that server increment updates the native counter and Svelte server props, and
  that server increments never reset or change either component's client state.
  """
  @moduletag :e2e

  defp native_increment_js, do: "document.querySelector(\"[data-testid='live-simple-counter-increment']\").click()"

  defp click_native_increment(session) do
    session |> Wallaby.Browser.execute_script(native_increment_js())
  end

  defp assert_client_values_unchanged(session, expected_first, expected_second) do
    client_values = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    assert length(client_values) == 2, "expected 2 SimpleCounter client value elements"
    actual_first = Wallaby.Element.text(Enum.at(client_values, 0))
    actual_second = Wallaby.Element.text(Enum.at(client_values, 1))
    assert actual_first == expected_first,
           "first component client state was affected by server increment (expected: #{expected_first}, got: #{actual_first})"
    assert actual_second == expected_second,
           "second component client state was affected by server increment (expected: #{expected_second}, got: #{actual_second})"
    session
  end

  defp wait_for_client_counters(session, count, attempts \\ 30)
  defp wait_for_client_counters(_session, _count, 0), do: :ok
  defp wait_for_client_counters(session, count, attempts) do
    els = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    if length(els) >= count do
      :ok
    else
      :timer.sleep(100)
      wait_for_client_counters(session, count, attempts - 1)
    end
  end

  # Wait for the native counter to show the given value (LiveView patch may be async).
  defp wait_for_counter_value(session, expected) when is_binary(expected) do
    wait_for_counter_value(session, expected, 100)
  end

  defp wait_for_counter_value(session, expected, 0) do
    el = session |> find(Query.css("[data-testid='live-simple-counter-value']"))
    actual = Wallaby.Element.text(el)
    raise "timeout waiting for counter value (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
  end

  defp wait_for_counter_value(session, expected, attempts) do
    el = session |> find(Query.css("[data-testid='live-simple-counter-value']"))
    case Wallaby.Element.text(el) do
      ^expected -> session
      _ -> :timer.sleep(100); wait_for_counter_value(session, expected, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-simple-counter")
    |> find(Query.css("h1", text: "Simple Counter Demo"))
  end

  test "renders initial native counter and two SimpleCounter components", %{session: session} do
    session = visit(session, "/live-simple-counter")

    native_value = session |> find(Query.css("[data-testid='live-simple-counter-value']"))
    assert Wallaby.Element.text(native_value) == "10"

    svelte_components = session |> all(Query.css("[data-name='SimpleCounter']"))
    assert length(svelte_components) == 2
  end

  test "clicking native +1 updates displayed number", %{session: session} do
    session =
      session
      |> visit("/live-simple-counter")
      |> click(Query.css("[data-testid='live-simple-counter-increment']"))

    native_value = session |> find(Query.css("[data-testid='live-simple-counter-value']"))
    assert Wallaby.Element.text(native_value) == "11"
  end

  test "increment updates server number in both Svelte components", %{session: session} do
    session =
      session
      |> visit("/live-simple-counter")
      |> click(Query.css("[data-testid='live-simple-counter-increment']"))

    # Each SimpleCounter has a Server card with span.text-brand for the server number
    svelte_server_numbers = session |> all(Query.css("[data-name='SimpleCounter'] span.text-brand"))
    assert length(svelte_server_numbers) >= 2
    for el <- Enum.take(svelte_server_numbers, 2), do: assert Wallaby.Element.text(el) == "11"
  end

  test "renders client counter at 1 in each SimpleCounter", %{session: session} do
    session = visit(session, "/live-simple-counter")
    # Wait for both Svelte components to mount and render client counter
    wait_for_client_counters(session, 2)
    client_values = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    assert length(client_values) == 2
    for el <- client_values, do: assert Wallaby.Element.text(el) == "1"
  end

  test "clicking client +1 updates only that component's client counter", %{session: session} do
    session = visit(session, "/live-simple-counter")
    # Wait for LiveView and Svelte to mount
    session |> find(Query.css("[data-testid='live-simple-counter-value']"))

    # Click the first SimpleCounter's client +1 button
    [first_client_btn | _] = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(first_client_btn)

    client_values = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    assert length(client_values) == 2
    # First component's client counter should be 2; second still 1
    assert Wallaby.Element.text(Enum.at(client_values, 0)) == "2"
    assert Wallaby.Element.text(Enum.at(client_values, 1)) == "1"
  end

  test "client state survives a single server increment", %{session: session} do
    session = visit(session, "/live-simple-counter")
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # Bump only the first component's client counter: 1 → 2
    [first_client_btn | _] = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(first_client_btn)
    :timer.sleep(200)
    assert_client_values_unchanged(session, "2", "1")

    # Server increment (10 → 11). Client state must not be affected.
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    assert_client_values_unchanged(session, "2", "1")
  end

  test "client state survives multiple consecutive server increments", %{session: session} do
    session = visit(session, "/live-simple-counter")
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # First component client: 1 → 2 → 3
    [first_client_btn | _] = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(first_client_btn)
    :timer.sleep(100)
    Wallaby.Element.click(first_client_btn)
    :timer.sleep(200)
    assert_client_values_unchanged(session, "3", "1")

    # Server 10→11: client state must be unchanged
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    assert_client_values_unchanged(session, "3", "1")

    # Server 11→12: client state must be unchanged
    session = session |> click_native_increment() |> wait_for_counter_value("12")
    assert_client_values_unchanged(session, "3", "1")

    # Server 12→13: client state must be unchanged
    session = session |> click_native_increment() |> wait_for_counter_value("13")
    assert_client_values_unchanged(session, "3", "1")
  end

  test "client state on second component only is unchanged by server increments", %{session: session} do
    session = visit(session, "/live-simple-counter")
    wait_for_client_counters(session, 2)
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # Bump only the second component's client counter (index 1)
    client_btns = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(Enum.at(client_btns, 1))
    :timer.sleep(200)
    assert_client_values_unchanged(session, "1", "2")

    # Server increment must not affect either client counter
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    assert_client_values_unchanged(session, "1", "2")

    session = session |> click_native_increment() |> wait_for_counter_value("12")
    assert_client_values_unchanged(session, "1", "2")
  end

  test "server increment never resets or changes client state on both components", %{session: session} do
    session = visit(session, "/live-simple-counter")
    wait_for_client_counters(session, 2)
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # Different client state on each: first=4 (3 clicks from 1), second=5 (4 clicks from 1)
    client_btns = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    # First component: 1 → 2 → 3 → 4
    for _ <- 1..3 do
      Wallaby.Element.click(Enum.at(client_btns, 0))
      :timer.sleep(100)
    end
    :timer.sleep(100)
    # Second component: 1 → 2 → 3 → 4 → 5
    for _ <- 1..4 do
      Wallaby.Element.click(Enum.at(client_btns, 1))
      :timer.sleep(80)
    end
    :timer.sleep(200)
    assert_client_values_unchanged(session, "4", "5")

    # Multiple server increments: client state must stay 4 and 5
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    assert_client_values_unchanged(session, "4", "5")
    session = session |> click_native_increment() |> wait_for_counter_value("12")
    assert_client_values_unchanged(session, "4", "5")
    session = session |> click_native_increment() |> wait_for_counter_value("13")
    assert_client_values_unchanged(session, "4", "5")
  end

  test "server increments first, then client state: client state still unaffected by later server increments", %{session: session} do
    session = visit(session, "/live-simple-counter")
    wait_for_client_counters(session, 2)
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # Server increments first (10 → 12)
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    session = session |> click_native_increment() |> wait_for_counter_value("12")

    # Then bump client state: first=2, second=4
    client_btns = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(Enum.at(client_btns, 0))
    :timer.sleep(100)
    for _ <- 1..3, do: (Wallaby.Element.click(Enum.at(client_btns, 1)); :timer.sleep(80))
    :timer.sleep(200)
    assert_client_values_unchanged(session, "2", "4")

    # More server increments must not touch client state
    session = session |> click_native_increment() |> wait_for_counter_value("13")
    assert_client_values_unchanged(session, "2", "4")
    session = session |> click_native_increment() |> wait_for_counter_value("14")
    assert_client_values_unchanged(session, "2", "4")
  end

  test "many server increments leave client state unchanged", %{session: session} do
    session = visit(session, "/live-simple-counter")
    wait_for_client_counters(session, 2)
    session |> find(Query.css("[data-testid='live-simple-counter-value']", text: "10"))

    # First component client = 2
    [first_btn | _] = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(first_btn)
    :timer.sleep(200)
    assert_client_values_unchanged(session, "2", "1")

    # 5 server increments (10 → 15): client state must stay 2 and 1
    session = session |> click_native_increment() |> wait_for_counter_value("11")
    assert_client_values_unchanged(session, "2", "1")
    session = session |> click_native_increment() |> wait_for_counter_value("12")
    assert_client_values_unchanged(session, "2", "1")
    session = session |> click_native_increment() |> wait_for_counter_value("13")
    assert_client_values_unchanged(session, "2", "1")
    session = session |> click_native_increment() |> wait_for_counter_value("14")
    assert_client_values_unchanged(session, "2", "1")
    session = session |> click_native_increment() |> wait_for_counter_value("15")
    assert_client_values_unchanged(session, "2", "1")
  end
end
