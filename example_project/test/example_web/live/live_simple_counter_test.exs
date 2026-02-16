defmodule ExampleWeb.LiveSimpleCounterTest do
  use ExampleWeb.FeatureCase, async: false

  @moduledoc """
  E2E test for the LiveSimpleCounter LiveView with Svelte SimpleCounter components.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders
  and that increment updates both the native counter and Svelte component props.
  """
  @moduletag :e2e

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

    client_values = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    assert length(client_values) == 2
    for el <- client_values, do: assert Wallaby.Element.text(el) == "1"
  end

  test "clicking client +1 updates only that component's client counter", %{session: session} do
    session = visit(session, "/live-simple-counter")

    # Click the first SimpleCounter's client +1 button
    [first_client_btn | _] = session |> all(Query.css("[data-testid='simple-counter-client-increment']"))
    Wallaby.Element.click(first_client_btn)

    client_values = session |> all(Query.css("[data-testid='simple-counter-client-value']"))
    assert length(client_values) == 2
    # First component's client counter should be 2; second still 1
    assert Wallaby.Element.text(Enum.at(client_values, 0)) == "2"
    assert Wallaby.Element.text(Enum.at(client_values, 1)) == "1"
  end
end
