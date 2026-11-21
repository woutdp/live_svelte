defmodule ExampleWeb.LiveClientSideLoadingTest do
  @moduledoc """
  E2E test for the LiveClientSideLoading LiveView (/live-client-side-loading).
  Validates that the page mounts, shows heading and description, and that both
  ClientSideLoading components hydrate and display content.
  """
  use ExampleWeb.FeatureCase, async: true

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-client-side-loading")

    Expect.to_be_visible!(
      Page.get_by_test_id(page, "client-side-loading-heading")
      |> Locator.filter(has_text: "Client-side loading")
    )
  end

  test "renders description", %{page: page} do
    Page.goto!(page, "/live-client-side-loading")

    Expect.to_be_visible!(
      Page.locator(page, "p",
        has_text:
          "Use the loading slot when SSR is disabled; the slot shows until the component hydrates on the client."
      )
    )
  end

  test "both components hydrate and show content", %{page: page} do
    Page.goto!(page, "/live-client-side-loading")
    Expect.to_be_visible!(Page.get_by_test_id(page, "client-side-loading-heading"))

    content = Page.get_by_test_id(page, "client-side-loading-content")
    Expect.to_have_count!(content, 2)
    Expect.to_have_text!(content, ["This is the component!", "This is the component!"])
  end

  test "both sections show hydrated content after load", %{page: page} do
    Page.goto!(page, "/live-client-side-loading")

    Expect.to_have_count!(Page.get_by_test_id(page, "client-side-loading-content"), 2)

    Expect.to_be_visible!(Page.get_by_test_id(page, "client-side-loading-client-section"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "client-side-loading-server-section"))
  end
end
