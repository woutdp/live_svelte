defmodule ExampleWeb.LiveNotesOtpTest do
  @moduledoc """
  E2E test for the LiveNotesOtp LiveView (/live-notes-otp).
  Validates that the page mounts with heading, description, form, empty state,
  and that creating and deleting notes works.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp note_items(session) do
    session |> all(Query.css("[data-testid='notes-otp-note']"))
  end

  defp wait_for_note_with_title(session, title, attempts \\ 50) do
    notes = note_items(session)
    found = Enum.any?(notes, fn el -> Wallaby.Element.text(el) =~ title end)

    cond do
      found ->
        session

      attempts == 0 ->
        raise "timeout waiting for note with title #{inspect(title)}"

      true ->
        :timer.sleep(100)
        wait_for_note_with_title(session, title, attempts - 1)
    end
  end

  test "page mounts and shows heading, description, and form", %{session: session} do
    session
    |> visit("/live-notes-otp")
    |> assert_has(Query.css("[data-testid='notes-otp-heading']", text: "Notes (OTP)"))
    |> assert_has(
      Query.css("p",
        text:
          "Ecto structs are encoded automatically. Changes sync in real time across all browsers via PubSub."
      )
    )
    |> assert_has(Query.css("[data-testid='notes-otp-app']"))
    |> assert_has(Query.css("[data-testid='notes-otp-form']"))
    |> assert_has(Query.css("[data-testid='notes-otp-title']"))
    |> assert_has(Query.css("[data-testid='notes-otp-submit']", text: "Add note"))
  end

  test "shows empty state or notes list", %{session: session} do
    session = visit(session, "/live-notes-otp")
    session |> assert_has(Query.css("[data-testid='notes-otp-list']"))
    # With no notes we see empty state; with existing notes we see note items
    empty_count = session |> all(Query.css("[data-testid='notes-otp-empty']")) |> length()
    note_count = session |> all(Query.css("[data-testid='notes-otp-note']")) |> length()

    assert empty_count > 0 or note_count > 0,
           "expected either empty state or at least one note"
  end

  test "creating a note shows it in the list", %{session: session} do
    session =
      session
      |> visit("/live-notes-otp")
      |> fill_in(Query.css("[data-testid='notes-otp-title']"), with: "E2E Test Note")
      |> fill_in(Query.css("[data-testid='notes-otp-content']"), with: "Optional content")
      |> click(Query.css("[data-testid='notes-otp-submit']"))

    session = wait_for_note_with_title(session, "E2E Test Note")
    notes = note_items(session)
    assert length(notes) >= 1
    assert Enum.any?(notes, fn el -> Wallaby.Element.text(el) =~ "E2E Test Note" end)
    assert Enum.any?(notes, fn el -> Wallaby.Element.text(el) =~ "Optional content" end)

    # Title and content inputs cleared after submit
    title_el = session |> find(Query.css("[data-testid='notes-otp-title']"))
    assert Wallaby.Element.attr(title_el, "value") == ""
  end

  test "deleting a note removes it from the list", %{session: session} do
    session =
      session
      |> visit("/live-notes-otp")
      |> fill_in(Query.css("[data-testid='notes-otp-title']"), with: "Note To Delete")
      |> click(Query.css("[data-testid='notes-otp-submit']"))

    session = wait_for_note_with_title(session, "Note To Delete")
    notes = note_items(session)
    assert length(notes) >= 1

    # Click delete on the first note (newest first; we just created this one)
    delete_btns = session |> all(Query.css("[data-testid='notes-otp-delete']"))
    Wallaby.Element.click(Enum.at(delete_btns, 0))

    # Wait for empty state or for the note to disappear
    :timer.sleep(400)
    notes_after = session |> all(Query.css("[data-testid='notes-otp-note']"))
    empty_visible = session |> all(Query.css("[data-testid='notes-otp-empty']")) |> length() > 0

    assert empty_visible or length(notes_after) < length(notes),
           "expected note to be deleted (empty state or fewer notes)"
  end
end
