defmodule ExampleWeb.LiveFormTest do
  @moduledoc """
  E2E tests for the LiveForm LiveView (/live-form).
  Validates useLiveForm() composable: initial render, server validation,
  and successful submit with form reset.
  """
  use ExampleWeb.FeatureCase, async: true

  test "initial form renders with inputs, no errors, and submit button", %{page: page} do
    Page.goto!(page, "/live-form")

    Expect.to_be_visible!(Page.get_by_test_id(page, "form-name-input"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "form-email-input"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "form-submit-btn"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "form-name-error"))
    Expect.not_to_be_visible!(Page.get_by_test_id(page, "form-email-error"))
  end

  test "server validation: submitting empty form shows required errors", %{page: page} do
    Page.goto!(page, "/live-form")
    Locator.click!(Page.get_by_test_id(page, "form-submit-btn"))

    Expect.to_be_visible!(Page.get_by_test_id(page, "form-name-error"))
    Expect.to_be_visible!(Page.get_by_test_id(page, "form-email-error"))
  end

  test "server validation: typing invalid email shows error after debounce", %{page: page} do
    Page.goto!(page, "/live-form")
    Locator.fill!(Page.get_by_test_id(page, "form-name-input"), "Alice")
    Locator.fill!(Page.get_by_test_id(page, "form-email-input"), "not-an-email")

    Expect.to_be_visible!(Page.get_by_test_id(page, "form-email-error"))
  end

  test "submitting valid form resets fields (re-submit verifies empty values)", %{page: page} do
    Page.goto!(page, "/live-form")
    name = Page.get_by_test_id(page, "form-name-input")
    email = Page.get_by_test_id(page, "form-email-input")
    submit = Page.get_by_test_id(page, "form-submit-btn")

    Locator.fill!(name, "Alice")
    Locator.fill!(email, "alice@example.com")
    Locator.click!(submit)

    # Wait for first submit to complete and form to reset.
    Expect.to_have_value!(name, "")
    Expect.to_have_value!(email, "")

    # Submit again with now-empty fields — server should reject with validation errors.
    Locator.click!(submit)

    Expect.to_be_visible!(Page.get_by_test_id(page, "form-name-error"))
  end
end
