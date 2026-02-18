defmodule ExampleWeb.PhoenixTest.LiveChatTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveChat (/live-chat).
  Validates that the page renders the join form, that setting a name shows the Chat
  Svelte component, and that simulating send_message updates messages in props.
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

  test "renders page heading and join form when not joined", %{conn: conn} do
    conn
    |> visit("/live-chat")
    |> assert_has("h2", text: "Chat")
    |> assert_has("p", text: "Enter your name to join; then send messages. Your name labels your bubbles.")
    |> assert_has("input[aria-label='Your name']")
    |> assert_has("button", text: "Join")
  end

  test "after joining, Chat component is shown with empty messages", %{conn: conn} do
    conn
    |> visit("/live-chat")
    |> unwrap(fn view ->
      view |> form("form[phx-submit='set_name']", %{"name" => "Alice"}) |> render_submit()
    end)
    |> assert_has("[data-name='Chat']")
    |> assert_has("[data-props*='\"name\":\"Alice\"']")
    |> assert_has("[data-props*='\"messages\":[]']")
  end

  test "simulating send_message after join updates Chat data-props", %{conn: conn} do
    conn
    |> visit("/live-chat")
    |> unwrap(fn view ->
      view |> form("form[phx-submit='set_name']", %{"name" => "Bob"}) |> render_submit()
    end)
    |> assert_has("[data-name='Chat']")
    |> unwrap(fn view ->
      render_click(view, "send_message", %{"body" => "Hello everyone"})
    end)
    |> assert_has("[data-props*='\"body\":\"Hello everyone\"']")
    |> assert_has("[data-props*='\"name\":\"Bob\"']")
  end
end
