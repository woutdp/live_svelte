defmodule ExampleWeb.PhoenixTest.LiveBreakingNewsTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveBreakingNews (/live-breaking-news).
  Validates that the page renders the inline ~V Svelte component with initial news,
  and that simulating add_news_item and remove_news_item update props.
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
    |> visit("/live-breaking-news")
    |> assert_has("h2", text: "Breaking News")
    |> assert_has("p", text: "Add headlines and control the ticker speed; remove items from the list.")
  end

  test "renders inline Svelte mount and initial news in props", %{conn: conn} do
    conn
    |> visit("/live-breaking-news")
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveBreakingNews']")
    |> assert_has("[data-props*='\"body\":\"Giant Pink Elephant Sighted Downtown\"']")
    |> assert_has("[data-props*='\"body\":\"Local Cat Becomes Mayor of Small Town\"']")
  end

  test "simulating add_news_item updates data-props", %{conn: conn} do
    conn
    |> visit("/live-breaking-news")
    |> assert_has("[data-name='_build/Elixir.ExampleWeb.LiveBreakingNews']")
    |> unwrap(fn view ->
      render_click(view, "add_news_item", %{"body" => "Extra headline"})
    end)
    |> assert_has("[data-props*='\"body\":\"Extra headline\"']")
  end

  test "simulating remove_news_item updates data-props", %{conn: conn} do
    conn
    |> visit("/live-breaking-news")
    |> assert_has("[data-props*='\"body\":\"Giant Pink Elephant Sighted Downtown\"']")
    |> unwrap(fn view ->
      render_click(view, "remove_news_item", %{"id" => 1})
    end)
    |> refute_has("[data-props*='\"body\":\"Giant Pink Elephant Sighted Downtown\"']")
  end
end
