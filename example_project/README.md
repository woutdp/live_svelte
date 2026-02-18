# Example

To start your Phoenix server:

-   Run `mix setup` to install and setup dependencies
-   Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

- Run all tests: `mix test`
- Run only E2E (browser) tests: `mix test --only e2e`

E2E tests use [Wallaby](https://hexdocs.pm/wallaby) and serve the app from **built** assets (`priv/static`). After changing Svelte (or other frontend) code, rebuild before E2E so tests see your changes:

```bash
mix assets.js && mix test --only e2e
```

Or use the alias (builds assets then runs tests; pass `--only e2e` to run only E2E):

```bash
mix test.e2e --only e2e
```

You need **Chrome** and **ChromeDriver** on your `PATH` for E2E. If Chromedriver is not installed, run `mix test --exclude e2e` to run the rest of the suite.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

-   Official website: https://www.phoenixframework.org/
-   Guides: https://hexdocs.pm/phoenix/overview.html
-   Docs: https://hexdocs.pm/phoenix
-   Forum: https://elixirforum.com/c/phoenix-forum
-   Source: https://github.com/phoenixframework/phoenix
