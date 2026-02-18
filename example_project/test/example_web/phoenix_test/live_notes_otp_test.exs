defmodule ExampleWeb.PhoenixTest.LiveNotesOtpTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveNotesOtp (/live-notes-otp).
  Validates that the page renders heading, description, NotesApp with notes,
  and that simulating create_note and delete_note update state.
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
    |> visit("/live-notes-otp")
    |> assert_has("[data-testid='notes-otp-heading']", text: "Notes (OTP)")
    |> assert_has("p", text: "Ecto structs are encoded automatically. Changes sync in real time across all browsers via PubSub.")
  end

  test "renders NotesApp with form and empty state or notes in props", %{conn: conn} do
    conn
    |> visit("/live-notes-otp")
    |> assert_has("[data-name='NotesApp']")
    |> assert_has("[data-testid='notes-otp-form']")
    |> assert_has("[data-testid='notes-otp-title']")
    |> assert_has("[data-testid='notes-otp-submit']", text: "Add note")
  end

  test "simulating create_note adds note to props", %{conn: conn} do
    conn
    |> visit("/live-notes-otp")
    |> assert_has("[data-name='NotesApp']")
    |> unwrap(fn view ->
      render_click(view, "create_note", %{
        "title" => "Phoenix Test Note",
        "content" => "Optional content",
        "color" => "#fef3c7"
      })
    end)
    |> assert_has("[data-props*='\"title\":\"Phoenix Test Note\"']")
    |> assert_has("[data-props*='\"content\":\"Optional content\"']")
  end

  test "simulating delete_note removes note from props", %{conn: conn} do
    conn =
      conn
      |> visit("/live-notes-otp")
      |> unwrap(fn view ->
        render_click(view, "create_note", %{
          "title" => "To Be Deleted",
          "content" => "",
          "color" => "#fef3c7"
        })
      end)
      |> assert_has("[data-props*='\"title\":\"To Be Deleted\"']")

    note = Enum.find(Example.Notes.list_notes(), &(&1.title == "To Be Deleted"))
    refute is_nil(note), "expected note To Be Deleted to exist after create_note"

    conn
    |> unwrap(fn view ->
      render_click(view, "delete_note", %{"id" => note.id})
    end)
    |> refute_has("[data-props*='\"title\":\"To Be Deleted\"']")
  end
end
