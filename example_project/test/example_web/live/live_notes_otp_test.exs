defmodule ExampleWeb.LiveNotesOtpTest do
  @moduledoc """
  E2E test for the LiveNotesOtp LiveView (/live-notes-otp).
  Validates that the page mounts with heading, description, form, empty state,
  and that creating and deleting notes works.
  """
  # Notes live in the shared database and are broadcast over PubSub to every browser.
  use ExampleWeb.FeatureCase, async: false

  setup tags, do: Example.DataCase.setup_sandbox(tags)

  defp notes(page), do: Page.get_by_test_id(page, "notes-otp-note")

  test "page mounts and shows heading, description, and form", %{page: page} do
    Page.goto!(page, "/live-notes-otp")

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "notes-otp-heading")
      |> Locator.filter(has_text: "Notes (OTP)")
    )

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text:
          "Ecto structs are encoded automatically. Changes sync in real time across all browsers via PubSub."
      )
    )

    Expect.to_be_visible!(Page.get_by_test_id(page, "notes-otp-app"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "notes-otp-form"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "notes-otp-title"))

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "notes-otp-submit")
      |> Locator.filter(has_text: "Add note")
    )
  end

  test "shows empty state or notes list", %{page: page} do
    Page.goto!(page, "/live-notes-otp")
    Expect.to_be_visible!(Page.get_by_test_id(page, "notes-otp-list"))

    # With no notes we see empty state; with existing notes we see note items
    Expect.to_be_visible!(
      Locator.or_(Page.get_by_test_id(page, "notes-otp-empty"), Locator.first(notes(page)))
    )
  end

  test "creating a note shows it in the list", %{page: page} do
    Page.goto!(page, "/live-notes-otp")
    title = Page.get_by_test_id(page, "notes-otp-title")

    Locator.fill!(title, "E2E Test Note")
    Locator.fill!(Page.get_by_test_id(page, "notes-otp-content"), "Optional content")
    Locator.click!(Page.get_by_test_id(page, "notes-otp-submit"))

    note = Locator.filter(notes(page), has_text: "E2E Test Note")
    Expect.to_be_visible!(note)
    Expect.to_contain_text!(note, "Optional content")

    # Title and content inputs cleared after submit
    Expect.to_have_value!(title, "")
  end

  test "deleting a note removes it from the list", %{page: page} do
    Page.goto!(page, "/live-notes-otp")

    Locator.fill!(Page.get_by_test_id(page, "notes-otp-title"), "Note To Delete")
    Locator.click!(Page.get_by_test_id(page, "notes-otp-submit"))

    note = Locator.filter(notes(page), has_text: "Note To Delete")
    Expect.to_be_visible!(note)

    # Click delete on the first note (newest first; we just created this one)
    Locator.click!(Locator.first(Page.get_by_test_id(page, "notes-otp-delete")))

    Expect.not_to_be_visible!(note)
  end
end
