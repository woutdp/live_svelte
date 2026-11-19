defmodule ExampleWeb.LiveEventReplyTest do
  @moduledoc """
  E2E tests for the LiveEventReply LiveView (/live-event-reply).
  Validates useEventReply() composable: initial render and request-response flow.
  """
  use ExampleWeb.FeatureCase, async: true

  test "initial render shows compute button with no result", %{page: page} do
    Page.goto!(page, "/live-event-reply")

    Expect.to_be_visible!(Page.get_by_test_id(page, "compute-btn"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "reply-result"))
  end

  test "clicking compute shows result from Phoenix reply", %{page: page} do
    Page.goto!(page, "/live-event-reply")
    Locator.click!(Page.get_by_test_id(page, "compute-btn"))

    Expect.to_be_visible!(Page.get_by_test_id(page, "reply-result"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "result-value"))
  end
end
