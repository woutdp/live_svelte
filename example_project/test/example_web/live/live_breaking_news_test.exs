defmodule ExampleWeb.LiveBreakingNewsTest do
  @moduledoc """
  E2E test for the LiveBreakingNews LiveView (/live-breaking-news).
  Validates that the page mounts with initial headlines, adding a headline via the UI
  works, and removing a headline removes it from the list.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp headline_items(session) do
    session |> all(Query.css("[data-testid='breaking-news-headlines'] li"))
  end

  defp wait_for_headline_with_text(session, text, attempts \\ 50) do
    items = headline_items(session)
    found = Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ text end)
    cond do
      found -> session
      attempts == 0 -> raise "timeout waiting for headline containing #{inspect(text)}"
      true ->
        :timer.sleep(100)
        wait_for_headline_with_text(session, text, attempts - 1)
    end
  end

  test "page mounts and shows heading, input, and initial headlines", %{session: session} do
    session
    |> visit("/live-breaking-news")
    |> assert_has(Query.css("h2", text: "Breaking News"))
    |> assert_has(Query.css("p", text: "Add headlines and control the ticker speed; remove items from the list."))
    |> assert_has(Query.css("[data-testid='breaking-news-new-headline']"))

    # Initial news has 5 items; at least one visible
    items = headline_items(session)
    assert length(items) >= 1
    assert Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ "Giant Pink Elephant" end)
  end

  test "adding a headline via the UI shows it in the list and clears the input", %{session: session} do
    session =
      session
      |> visit("/live-breaking-news")
      |> fill_in(Query.css("[data-testid='breaking-news-new-headline']"), with: "Test headline")
      |> click(Query.button("Add"))

    session = wait_for_headline_with_text(session, "Test headline")
    items = headline_items(session)
    assert Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ "Test headline" end)

    input = session |> find(Query.css("[data-testid='breaking-news-new-headline']"))
    assert Wallaby.Element.attr(input, "value") == ""
  end

  test "removing a headline removes it from the list", %{session: session} do
    session = visit(session, "/live-breaking-news")
    session = wait_for_headline_with_text(session, "Giant Pink Elephant")
    count_before = headline_items(session) |> length()

    # Click the first Remove button (first headline)
    remove_btns = session |> all(Query.css("[data-testid='breaking-news-headlines'] li button"))
    assert length(remove_btns) >= 1
    Wallaby.Element.click(Enum.at(remove_btns, 0))

    # Wait for one item to disappear
    session = wait_for_headline_removed(session, "Giant Pink Elephant", 30)
    count_after = headline_items(session) |> length()
    assert count_after == count_before - 1
  end

  test "faster/slower buttons update ticker rate", %{session: session} do
    session =
      session
      |> visit("/live-breaking-news")
      |> assert_has(Query.css("[data-testid='breaking-news-ticker']"))

    ticker = session |> find(Query.css("[data-testid='breaking-news-ticker']"))
    assert Wallaby.Element.attr(ticker, "data-rate") == "-150"

    session = session |> click(Query.button("← Faster"))
    session = wait_for_ticker_rate(session, "-170")

    session = session |> click(Query.button("Slower →"))
    _session = wait_for_ticker_rate(session, "-150")
  end

  defp wait_for_headline_removed(session, text, attempts) do
    items = headline_items(session)
    found = Enum.any?(items, fn el -> Wallaby.Element.text(el) =~ text end)
    cond do
      not found -> session
      attempts == 0 -> raise "timeout waiting for headline #{inspect(text)} to be removed"
      true ->
        :timer.sleep(100)
        wait_for_headline_removed(session, text, attempts - 1)
    end
  end

  defp wait_for_ticker_rate(session, expected, attempts \\ 30) do
    ticker = session |> find(Query.css("[data-testid='breaking-news-ticker']"))

    case Wallaby.Element.attr(ticker, "data-rate") do
      ^expected ->
        session

      _ ->
        if attempts == 0 do
          actual = Wallaby.Element.attr(ticker, "data-rate")
          raise "timeout waiting for ticker rate (expected: #{inspect(expected)}, actual: #{inspect(actual)})"
        end

        :timer.sleep(50)
        wait_for_ticker_rate(session, expected, attempts - 1)
    end
  end
end
