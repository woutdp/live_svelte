defmodule ExampleWeb.FeatureCase do
  @moduledoc """
  Case for browser E2E tests using Playwright (playwright_ex): each test gets a `page` of its
  own browser context, against the endpoint on port 4002.
  Tagged `:e2e`: run only these with `mix test --only e2e`, skip them with `mix test --exclude e2e`.
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      @moduletag :e2e
    end
  end
end
