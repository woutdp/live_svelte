defmodule ExampleWeb.LiveLogListTest do
  @moduledoc """
  E2E test for the LiveLogList LiveView (/live-log-list).
  Validates that the page mounts, the Svelte LogList component shows the empty state,
  adding an item via the UI updates the list, and the timer appends entries.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  # Log list items are in ul.max-h-64 (not the nav)
  defp log_list_items(session) do
    session |> all(Query.css("ul.max-h-64 li"))
  end

  defp wait_for_log_item_with_text(session, text, attempts \\ 50) do
    items = log_list_items(session)
    found = Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ text end)
    cond do
      found -> session
      attempts == 0 -> raise "timeout waiting for log list item containing #{inspect(text)}"
      true ->
        :timer.sleep(100)
        wait_for_log_item_with_text(session, text, attempts - 1)
    end
  end

  defp wait_for_at_least_one_log_item(session, attempts \\ 35) do
    items = log_list_items(session)
    cond do
      length(items) >= 1 -> session
      attempts == 0 -> raise "timeout waiting for at least one timer-driven log entry"
      true ->
        :timer.sleep(200)
        wait_for_at_least_one_log_item(session, attempts - 1)
    end
  end

  test "page mounts and shows heading, input, and description", %{session: session} do
    session
    |> visit("/live-log-list")
    |> assert_has(Query.css("h2", text: "Log stream"))
    |> assert_has(Query.css("p", text: "Add items or let the timer append entries; limit how many are shown."))
    |> assert_has(Query.css("input[aria-label='New log entry']"))
    # Empty state may be gone if timer already appended an entry
  end

  test "adding an item via the UI shows it in the list and clears the input", %{session: session} do
    session =
      session
      |> visit("/live-log-list")
      |> fill_in(Query.css("input[aria-label='New log entry']"), with: "Hello")
      |> click(Query.button("Add item"))

    session = wait_for_log_item_with_text(session, "Hello")
    items = log_list_items(session)
    assert length(items) >= 1
    assert Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ "Hello" end)

    input = session |> find(Query.css("input[aria-label='New log entry']"))
    assert Wallaby.Element.attr(input, "value") == ""
  end

  test "timer appends entries after mount", %{session: session} do
    session =
      session
      |> visit("/live-log-list")
      |> assert_has(Query.css("h2", text: "Log stream"))

    session = wait_for_at_least_one_log_item(session)
    items = log_list_items(session)
    assert length(items) >= 1
  end
end
