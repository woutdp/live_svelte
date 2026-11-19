defmodule ExampleWeb.LiveChatTest do
  @moduledoc """
  E2E test for the LiveChat LiveView (/live-chat).
  Validates that the page mounts with the join form, joining shows the chat UI,
  and sending a message displays it in the chat.
  """
  use ExampleWeb.FeatureCase, async: true

  defp join_button(page) do
    Page.locator(page, "[data-testid='chat-join-form'] button", has_text: "Join")
  end

  test "page mounts and shows heading and join form when not joined", %{page: page} do
    Page.goto!(page, "/live-chat")

    Expect.to_be_visible!(Page.locator(page, "h2", has_text: "Chat"))

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text: "Enter your name to join; then send messages. Your name labels your bubbles."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "chat-join-name"))
    Expect.to_be_visible!(join_button(page))
  end

  test "useLiveConnection: reconnecting banner absent when connected (happy path)", %{page: page} do
    Page.goto!(page, "/live-chat")
    Locator.fill!(Page.get_by_test_id(page, "chat-join-name"), "Alice")
    Locator.click!(join_button(page))

    Expect.to_be_visible!(Page.get_by_test_id(page, "chat-message-input"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "chat-reconnecting"))
  end

  test "joining with a name shows chat UI with message input", %{page: page} do
    Page.goto!(page, "/live-chat")
    Locator.fill!(Page.get_by_test_id(page, "chat-join-name"), "Alice")
    Locator.click!(join_button(page))

    Expect.to_be_visible!(Page.get_by_test_id(page, "chat-message-input"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "chat-send"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "chat-user-badge")
      |> Locator.filter(has_text: "Alice")
    )
  end

  test "sending a message shows it in the chat", %{page: page} do
    Page.goto!(page, "/live-chat")
    Locator.fill!(Page.get_by_test_id(page, "chat-join-name"), "Bob")
    Locator.click!(join_button(page))

    input = Page.get_by_test_id(page, "chat-message-input")
    Expect.to_be_visible!(input)
    Locator.fill!(input, "Hello from E2E")
    Locator.click!(Page.get_by_test_id(page, "chat-send"))

    Expect.to_contain_text!(Page.get_by_test_id(page, "chat-message"), "Hello from E2E")

    # Input cleared after send
    Expect.to_have_value!(input, "")
  end
end
