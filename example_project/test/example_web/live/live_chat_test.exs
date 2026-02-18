defmodule ExampleWeb.LiveChatTest do
  @moduledoc """
  E2E test for the LiveChat LiveView (/live-chat).
  Validates that the page mounts with the join form, joining shows the chat UI,
  and sending a message displays it in the chat.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp chat_bubbles(session) do
    session |> all(Query.css(".chat-bubble"))
  end

  defp wait_for_chat_bubble_with_text(session, text, attempts \\ 50) do
    bubbles = chat_bubbles(session)
    found = Enum.any?(bubbles, fn el -> Wallaby.Element.text(el) =~ text end)
    cond do
      found -> session
      attempts == 0 -> raise "timeout waiting for chat bubble containing #{inspect(text)}"
      true ->
        :timer.sleep(100)
        wait_for_chat_bubble_with_text(session, text, attempts - 1)
    end
  end

  test "page mounts and shows heading and join form when not joined", %{session: session} do
    session
    |> visit("/live-chat")
    |> assert_has(Query.css("h2", text: "Chat"))
    |> assert_has(Query.css("p", text: "Enter your name to join; then send messages. Your name labels your bubbles."))
    |> assert_has(Query.css("input[aria-label='Your name']"))
    |> assert_has(Query.css("button", text: "Join"))
  end

  test "joining with a name shows chat UI with message input", %{session: session} do
    session =
      session
      |> visit("/live-chat")
      |> fill_in(Query.css("input[aria-label='Your name']"), with: "Alice")
      |> click(Query.button("Join"))

    session
    |> assert_has(Query.css("input[aria-label='Message']"))
    |> assert_has(Query.css("button", text: "Send"))
    |> assert_has(Query.css(".badge", text: "Alice"))
  end

  test "sending a message shows it in the chat", %{session: session} do
    session =
      session
      |> visit("/live-chat")
      |> fill_in(Query.css("input[aria-label='Your name']"), with: "Bob")
      |> click(Query.button("Join"))

    session
    |> assert_has(Query.css("input[aria-label='Message']"))
    |> fill_in(Query.css("input[aria-label='Message']"), with: "Hello from E2E")
    |> click(Query.css("button", text: "Send"))

    session = wait_for_chat_bubble_with_text(session, "Hello from E2E")
    bubbles = chat_bubbles(session)
    assert length(bubbles) >= 1
    assert Enum.any?(bubbles, fn el -> Wallaby.Element.text(el) =~ "Hello from E2E" end)

    # Input cleared after send
    input = session |> find(Query.css("input[aria-label='Message']"))
    assert Wallaby.Element.attr(input, "value") == ""
  end
end
