defmodule ExampleWeb.LiveUploadTest do
  @moduledoc """
  E2E tests for the LiveUpload LiveView (/live-upload).
  Validates useLiveUpload() composable: initial render, file selection,
  upload submission, and entry cancellation.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Wait for an element with the given testid to appear (retries up to 3s).
  defp wait_for(session, testid, attempts \\ 30)
  defp wait_for(_session, testid, 0), do: raise("timeout waiting for [data-testid='#{testid}']")

  defp wait_for(session, testid, attempts) do
    els = session |> all(Query.css("[data-testid='#{testid}']"))

    if length(els) > 0 do
      session
    else
      :timer.sleep(100)
      wait_for(session, testid, attempts - 1)
    end
  end

  # Wait for an element with the given testid to disappear (retries up to 3s).
  defp wait_for_gone(session, testid, attempts \\ 30)

  defp wait_for_gone(_session, testid, 0),
    do: raise("timeout waiting for [data-testid='#{testid}'] to disappear")

  defp wait_for_gone(session, testid, attempts) do
    els = session |> all(Query.css("[data-testid='#{testid}']"))

    if length(els) == 0 do
      session
    else
      :timer.sleep(100)
      wait_for_gone(session, testid, attempts - 1)
    end
  end

  # Create a temp file for upload tests, cleaned up after the test.
  defp tmp_upload_file(content \\ "test upload content") do
    path =
      Path.join(System.tmp_dir!(), "live_upload_test_#{System.unique_integer([:positive])}.txt")

    File.write!(path, content)
    path
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "initial upload page renders container and select button with no entries", %{
    session: session
  } do
    session
    |> visit("/live-upload")
    |> wait_for("upload-container")
    |> assert_has(Query.css("[data-testid='upload-container']"))
    |> assert_has(Query.css("[data-testid='pick-files-btn']"))
    |> assert_has(Query.css("[data-testid='drop-zone']"))
    |> refute_has(Query.css("[data-testid='upload-entry']"))
    |> refute_has(Query.css("[data-testid='uploaded-file']"))
  end

  test "selecting a file shows it in the entry list", %{session: session} do
    path = tmp_upload_file("hello from test")

    on_exit(fn -> File.rm(path) end)

    session =
      session
      |> visit("/live-upload")
      |> wait_for("pick-files-btn")

    # The hidden file input is created by useLiveUpload's onMount.
    # Use visible: false so Wallaby can locate the hidden input.
    session =
      session
      |> attach_file(Query.css("input[type=file]", visible: false), path: path)

    session
    |> wait_for("upload-entry")
    |> assert_has(Query.css("[data-testid='upload-entry']"))
    |> assert_has(Query.css("[data-testid='entry-name']"))
    |> assert_has(Query.css("[data-testid='cancel-entry-btn']"))
  end

  test "uploading a file triggers save event and shows it in uploaded list", %{session: session} do
    path = tmp_upload_file("upload me please")

    on_exit(fn -> File.rm(path) end)

    session =
      session
      |> visit("/live-upload")
      |> wait_for("pick-files-btn")
      |> attach_file(Query.css("input[type=file]", visible: false), path: path)

    session =
      session
      |> wait_for("upload-submit-btn")
      |> click(Query.css("[data-testid='upload-submit-btn']"))

    session
    |> wait_for("uploaded-file")
    |> assert_has(Query.css("[data-testid='uploaded-file']"))
    |> assert_has(Query.css("[data-testid='uploaded-name']"))
  end

  test "cancelling an entry removes it from the list", %{session: session} do
    path = tmp_upload_file("cancel me")

    on_exit(fn -> File.rm(path) end)

    session =
      session
      |> visit("/live-upload")
      |> wait_for("pick-files-btn")
      |> attach_file(Query.css("input[type=file]", visible: false), path: path)

    session =
      session
      |> wait_for("cancel-entry-btn")
      |> click(Query.css("[data-testid='cancel-entry-btn']"))

    session
    |> wait_for_gone("upload-entry")
    |> refute_has(Query.css("[data-testid='upload-entry']"))
  end
end
