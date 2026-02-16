defmodule ExampleWeb.FeatureCase do
  @moduledoc """
  Case for browser E2E tests using Wallaby.
  Use `@tag :e2e` on tests and run with: mix test --only e2e
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      @endpoint ExampleWeb.Endpoint
    end
  end

  setup tags do
    # Start Wallaby only when running E2E tests (avoids requiring chromedriver for plain mix test).
    # If chromedriver is not installed, setup will fail; run `mix test --exclude e2e` to skip E2E.
    {:ok, _} = Application.ensure_all_started(:wallaby)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Example.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Example.Repo, {:shared, self()})
    end

    {:ok, session} = Wallaby.start_session()
    on_exit(fn -> Wallaby.end_session(session) end)

    {:ok, session: session}
  end
end
