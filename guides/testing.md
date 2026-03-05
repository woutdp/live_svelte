# Testing

The LiveSvelte example project has two complementary test layers: fast server-side tests via PhoenixTest, and full-stack browser tests via Wallaby.

## Build Before Testing

> #### Critical: Always Build Before Tests {: .warning}
>
> After any changes to Svelte components or JS files, always run:
>
> ```bash
> cd example_project
> mix assets.build && mix compile
> ```
>
> `mix assets.build` runs Vite builds (client + SSR). `mix compile` copies the updated SSR bundle into `_build/`. Forgetting this step is the most common cause of "my JS changes have no effect" test failures.

## PhoenixTest (Server-Side, Fast)

PhoenixTest tests validate server-side behavior without a browser. They are fast, reliable, and do not require chromedriver.

```bash
cd example_project
mix test --only phoenix_test
```

Tag test modules with `@moduletag :phoenix_test`:

```elixir
defmodule MyAppWeb.CounterTest do
  use MyAppWeb.ConnCase, async: true

  @moduletag :phoenix_test

  import PhoenixTest

  test "increments counter", %{conn: conn} do
    conn
    |> visit("/counter")
    |> assert_has("h1", text: "Counter")
    |> assert_has("[data-props*='\"count\":0']")
  end
end
```

### What PhoenixTest Can Verify

- LiveView renders correct HTML (headings, labels, lists)
- `data-props` contains the expected JSON for Svelte components
- LiveView events update assigns and re-render correctly
- Server-side rendered content

### What PhoenixTest Cannot Verify

- Whether Svelte components use the props they receive
- Client-side rendering (Svelte output)
- Interactions inside Svelte-rendered elements (SSR is off in tests by default)

### Workaround for Svelte-Rendered Elements

Use `unwrap/2` to access the LiveView test process and trigger events directly:

```elixir
session
|> unwrap(fn view ->
  Phoenix.LiveViewTest.render_click(view, "increment")
end)
|> assert_has("[data-props*='\"count\":1']")
```

## Wallaby E2E (Browser-Based, Full Stack)

Wallaby tests use chromedriver to run a real browser. They validate the full pipeline: LiveView → SvelteHook → Svelte component.

```bash
cd example_project
mix test --only e2e
```

Tag test modules with `@moduletag :e2e`:

```elixir
defmodule MyAppWeb.CounterE2ETest do
  use MyAppWeb.FeatureCase, async: false

  @moduletag :e2e

  test "Svelte counter increments", %{session: session} do
    session
    |> visit("/counter")
    |> assert_text("Count: 0")
    |> click(button("Increment"))
    |> assert_text("Count: 1")
  end
end
```

### What Wallaby Can Verify

- Svelte components render the correct data from server props
- Client-side interactions (buttons rendered by Svelte, not LiveView)
- Full data flow from server through to Svelte re-renders
- HMR and dynamic updates

### Requirements

Wallaby requires chromedriver installed and available in `PATH`:

```bash
# Check if chromedriver is available
chromedriver --version

# On macOS with Homebrew:
brew install chromedriver

# On Ubuntu/Debian:
sudo apt-get install chromium-driver
```

## Running Both Layers

```bash
# Server-side only (fast, no browser needed)
mix assets.build && mix test --only phoenix_test

# Browser E2E only
mix assets.build && mix test --only e2e

# Everything
mix assets.build && mix test
```

## `LiveSvelte.Test` — Component Introspection

`LiveSvelte.Test` provides helper functions to inspect Svelte component props in server-side tests:

```elixir
import LiveSvelte.Test

# In a PhoenixTest or ConnCase test:
{:ok, view, html} = live(conn, "/counter")
component = get_svelte(html, name: "Counter")

assert component.name == "Counter"
assert component.props["count"] == 0
```

### `get_svelte/1` and `get_svelte/2`

```elixir
# Get first Svelte component in the HTML
component = get_svelte(html)

# Get component by name
component = get_svelte(html, name: "Counter")

# Get component by DOM id
component = get_svelte(html, id: "Counter-1")

# Get from a LiveView directly
{:ok, view, _html} = live(conn, "/counter")
component = get_svelte(view, name: "Counter")
```

The returned map has:
- `name` — component name string
- `id` — DOM id of the component wrapper
- `props` — decoded props map (string keys)
- `slots` — map of slot name → HTML string
- `ssr` — boolean, whether SSR was used

### Example: Asserting Props after Events

```elixir
test "props update after event", %{conn: conn} do
  {:ok, view, html} = live(conn, "/counter")

  # Initial props
  assert get_svelte(html, name: "Counter").props["count"] == 0

  # Trigger event
  html = render_click(view, "increment")

  # Updated props
  assert get_svelte(html, name: "Counter").props["count"] == 1
end
```

## Vitest (JavaScript Unit Tests)

JavaScript composables and utilities have unit tests using Vitest:

```bash
cd example_project/assets
npm test           # Run tests once
npm run test:watch # Watch mode
```

Test files are colocated with source files (`*.test.ts`).

## Tagging Convention

Use `@moduletag` (not `@tag`) for consistent filtering:

```elixir
# ✅ Correct — applies to ALL tests in the module
@moduletag :phoenix_test

# ❌ Wrong — only applies to the NEXT test
@tag :phoenix_test
```

## Test File Layout

```
example_project/test/example_web/
├── phoenix_test/              # PhoenixTest (server-side)
│   ├── hello_world_test.exs
│   ├── live_struct_test.exs
│   └── ...
└── live/                      # Wallaby E2E (browser)
    ├── live_struct_test.exs
    └── ...
```

## SSR Testing

SSR is off in tests by default. To test SSR output:

```elixir
defmodule MyAppWeb.SsrTest do
  use MyAppWeb.ConnCase, async: false  # SSR state is global — must use async: false

  setup do
    Application.put_env(:live_svelte, :ssr, true)
    on_exit(fn -> Application.put_env(:live_svelte, :ssr, false) end)
    :ok
  end

  test "renders SSR HTML on first request", %{conn: conn} do
    # Use get/html_response for dead render — NOT visit/2
    html = conn |> get("/counter") |> html_response(200)
    assert html =~ ~s(data-ssr="true")
    assert html =~ "<div"  # SSR produced some HTML
  end
end
```

> Use `get/2` + `html_response/2` for SSR checks. `visit/2` from PhoenixTest connects the LiveView socket and transitions past the initial dead render.
