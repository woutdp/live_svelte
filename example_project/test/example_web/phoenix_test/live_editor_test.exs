defmodule ExampleWeb.PhoenixTest.LiveEditorTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveEditor (/live-editor).
  Validates server-side rendering, data-props contract, and sync_content event handling.
  Editor.js is browser-only; these tests skip SSR and validate the LiveView layer only.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  test "renders page heading", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("h1", text: "Rich Editor (@attach)")
  end

  test "renders description mentioning @attach", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("p", text: "@attach")
  end

  test "renders RichEditor Svelte component with initialContent prop", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("[data-name='RichEditor']", count: 1)
    |> assert_has("[data-props*='initialContent']")
    |> assert_has("[data-props*='Welcome to the Rich Editor']")
  end

  test "initial block count is 2", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("[data-testid='block-count']", text: "2")
  end

  test "no-save-yet message is shown initially", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("[data-testid='no-save-yet']")
  end

  test "sync_content event updates block count and removes no-save message", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> assert_has("[data-testid='no-save-yet']")
    |> assert_has("[data-testid='block-count']", text: "2")
    |> unwrap(fn view ->
      render_click(view, "sync_content", %{
        "blocks" => [
          %{"type" => "header", "data" => %{"text" => "Hello", "level" => 2}},
          %{"type" => "paragraph", "data" => %{"text" => "World"}},
          %{"type" => "paragraph", "data" => %{"text" => "Third block"}}
        ]
      })
    end)
    |> assert_has("[data-testid='block-count']", text: "3")
    |> refute_has("[data-testid='no-save-yet']")
  end

  test "sync_content event with single block updates count to 1", %{conn: conn} do
    conn
    |> visit("/live-editor")
    |> unwrap(fn view ->
      render_click(view, "sync_content", %{
        "blocks" => [
          %{"type" => "header", "data" => %{"text" => "Only block", "level" => 2}}
        ]
      })
    end)
    |> assert_has("[data-testid='block-count']", text: "1")
  end
end
