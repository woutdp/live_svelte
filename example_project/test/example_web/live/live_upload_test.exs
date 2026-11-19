defmodule ExampleWeb.LiveUploadTest do
  @moduledoc """
  E2E tests for the LiveUpload LiveView (/live-upload).
  Validates useLiveUpload() composable: initial render, file selection,
  upload submission, and entry cancellation.
  """
  use ExampleWeb.FeatureCase, async: true

  defp tmp_upload_file(content) do
    path =
      Path.join(
        System.tmp_dir!(),
        "live_upload_test_#{System.unique_integer([:positive])}.txt"
      )

    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  test "initial upload page renders container and select button with no entries", %{page: page} do
    Page.goto!(page, "/live-upload")

    Expect.to_be_visible!(Page.get_by_test_id(page, "upload-container"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "pick-files-btn"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "drop-zone"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "upload-entry"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "uploaded-file"))
  end

  test "selecting a file shows it in the entry list", %{page: page} do
    path = tmp_upload_file("hello from test")

    Page.goto!(page, "/live-upload")
    Expect.to_be_visible!(Page.get_by_test_id(page, "pick-files-btn"))
    Locator.set_input_files!(Page.locator(page, "input[type=file]"), path)

    Expect.to_be_visible!(Page.get_by_test_id(page, "upload-entry"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "entry-name"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "cancel-entry-btn"))
  end

  test "uploading a file triggers save event and shows it in uploaded list", %{page: page} do
    path = tmp_upload_file("upload me please")

    Page.goto!(page, "/live-upload")
    Expect.to_be_visible!(Page.get_by_test_id(page, "pick-files-btn"))
    Locator.set_input_files!(Page.locator(page, "input[type=file]"), path)

    Locator.click!(Page.get_by_test_id(page, "upload-submit-btn"))

    Expect.to_be_visible!(Page.get_by_test_id(page, "uploaded-file"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "uploaded-name"))
  end

  test "cancelling an entry removes it from the list", %{page: page} do
    path = tmp_upload_file("cancel me")

    Page.goto!(page, "/live-upload")
    Expect.to_be_visible!(Page.get_by_test_id(page, "pick-files-btn"))
    Locator.set_input_files!(Page.locator(page, "input[type=file]"), path)

    Locator.click!(Page.get_by_test_id(page, "cancel-entry-btn"))

    Expect.not_to_be_visible!(Page.get_by_test_id(page, "upload-entry"))
  end
end
