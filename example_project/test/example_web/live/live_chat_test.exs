defmodule ExampleWeb.LiveChatTest do
  @moduledoc """
  E2E test for the LiveChat LiveView (/live-chat).
  Validates that the page mounts with the join form, joining shows the chat UI,
  and sending a message displays it in the chat.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp chat_bubbles(session) do
    session |> all(Query.css("[data-testid='chat-message']"))
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
    |> assert_has(Query.css("[data-testid='chat-join-name']"))
    |> assert_has(Query.css("[data-testid='chat-join-form'] button", text: "Join"))
  end

  test "joining with a name shows chat UI with message input", %{session: session} do
    session =
      session
      |> visit("/live-chat")
      |> fill_in(Query.css("[data-testid='chat-join-name']"), with: "Alice")
      |> click(Query.css("[data-testid='chat-join-form'] button", text: "Join"))

    session
    |> assert_has(Query.css("[data-testid='chat-message-input']"))
    |> assert_has(Query.css("[data-testid='chat-send']"))
    |> assert_has(Query.css("[data-testid='chat-user-badge']", text: "Alice"))
  end

  test "sending a message shows it in the chat", %{session: session} do
    session =
      session
      |> visit("/live-chat")
      |> fill_in(Query.css("[data-testid='chat-join-name']"), with: "Bob")
      |> click(Query.css("[data-testid='chat-join-form'] button", text: "Join"))

    session
    |> assert_has(Query.css("[data-testid='chat-message-input']"))
    |> fill_in(Query.css("[data-testid='chat-message-input']"), with: "Hello from E2E")
    |> click(Query.css("[data-testid='chat-send']"))

    session = wait_for_chat_bubble_with_text(session, "Hello from E2E")
    bubbles = chat_bubbles(session)
    assert length(bubbles) >= 1
    assert Enum.any?(bubbles, fn el -> Wallaby.Element.text(el) =~ "Hello from E2E" end)

    # Input cleared after send
    input = session |> find(Query.css("[data-testid='chat-message-input']"))
    assert Wallaby.Element.attr(input, "value") == ""
  end
end
