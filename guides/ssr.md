# Server-Side Rendering

LiveSvelte supports server-side rendering (SSR) of Svelte components, which provides meaningful HTML on the first paint before the JavaScript bundle loads.

## How SSR Works

When SSR is active, the initial (dead) render calls Node.js to execute Svelte's `render()` function server-side. The result is embedded directly in the HTML response:

1. LiveSvelte calls `SSR.render(component_name, props, slots)`
2. `render()` returns `%{"head" => "<style>...</style>", "html" => "<div>...</div>", "css" => %{"code" => "..."}}`
3. The `head` and CSS styles are included in the page; `html` is placed inside the `data-svelte-target` div
4. When JavaScript loads, the `SvelteHook` hydrates the existing DOM instead of mounting fresh

## SSR Modes

LiveSvelte has two SSR modules for different environments:

### NodeJS Mode (Production)

Uses [`elixir-nodejs`](https://github.com/revelrylabs/elixir-nodejs) to run a pool of Node.js workers that execute the SSR bundle.

```elixir
# config/prod.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

The SSR bundle is built by:
```bash
mix assets.js  # runs: npx vite build --config vite.ssr.config.js
```

This produces `priv/svelte/server.js`, which the NodeJS supervisor loads on application start.

### ViteJS Mode (Development)

Forwards SSR requests to the Vite dev server over HTTP. This provides instant HMR without rebuilding the SSR bundle on every change.

```elixir
# config/dev.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

> #### ViteJS Mode Requires Vite Dev Server {: .warning}
>
> `LiveSvelte.SSR.ViteJS` only works when `mix phx.server` is running alongside the Vite dev server started by Phoenix's watchers. If the Vite server is not running, SSR will silently fall back to client-only rendering.

## Configuration

Enable/disable SSR globally:

```elixir
# config/config.exs
config :live_svelte, ssr: true   # enabled (default)
config :live_svelte, ssr: false  # disabled
```

Select SSR module:

```elixir
config :live_svelte, ssr_module: LiveSvelte.SSR.NodeJS   # production (default)
config :live_svelte, ssr_module: LiveSvelte.SSR.ViteJS   # development
```

## Per-Component SSR Opt-Out

Disable SSR for a specific component:

```heex
<.svelte name="HeavyChart" props={%{data: @data}} socket={@socket} ssr={false} />
```

Components with `ssr={false}` render a loading slot or nothing on the first paint, then mount client-side normally.

## HMR in Development

When running with `LiveSvelte.SSR.ViteJS`, changes to Svelte files trigger automatic hot module replacement. The `SvelteHook` re-mounts affected components without a full page reload.

Add the `LiveSvelte.Reload` module to your layouts to enable this:

```elixir
# config/dev.exs — added by the Igniter installer
config :live_svelte,
  vite_host: "http://localhost:5173"
```

Use `vite_assets/0` in your layout to include Vite's HMR client:

```heex
<!-- In your root layout (dev only) -->
<%= if Application.get_env(:live_svelte, :ssr_module) == LiveSvelte.SSR.ViteJS do %>
  <LiveSvelte.Reload.vite_assets path="/assets/js/app.js" />
<% end %>
```

## Loading Slot

Show content while a component is loading (only when `ssr={false}`):

```heex
<.svelte name="SlowChart" props={%{data: @data}} socket={@socket} ssr={false}>
  <:loading>
    <div class="spinner">Loading chart...</div>
  </:loading>
</.svelte>
```

> #### Loading Slot + SSR Incompatible {: .warning}
>
> The `:loading` slot is mutually exclusive with SSR. Using both together produces a compile warning. If SSR is active, the loading slot is ignored.

## Telemetry

LiveSvelte emits telemetry events for SSR operations:

| Event | When |
|-------|------|
| `[:live_svelte, :ssr, :start]` | SSR render begins |
| `[:live_svelte, :ssr, :stop]` | SSR render completes; includes `duration_microseconds` measurement |
| `[:live_svelte, :ssr, :exception]` | SSR render throws an exception |

Attach handlers for observability:

```elixir
:telemetry.attach(
  "live-svelte-ssr",
  [:live_svelte, :ssr, :stop],
  fn _event, measurements, _metadata, _config ->
    Logger.debug("SSR render took #{measurements.duration_microseconds}µs")
  end,
  nil
)
```

## Testing with SSR

SSR is disabled in the test environment by default. To write tests that verify SSR output, enable it per test suite:

```elixir
defmodule MyAppWeb.SsrTest do
  use MyAppWeb.ConnCase, async: false  # must be async: false

  setup do
    Application.put_env(:live_svelte, :ssr, true)
    on_exit(fn -> Application.put_env(:live_svelte, :ssr, false) end)
    :ok
  end

  test "renders SSR HTML", %{conn: conn} do
    html = conn |> get("/counter") |> html_response(200)
    assert html =~ "data-ssr=\"true\""
  end
end
```

Use `get/2` + `html_response/2` for initial HTML checks — `visit/2` from PhoenixTest connects the socket and transitions past the dead render.

## Production Deployment

See [Deployment](deployment.md) for complete Node.js setup instructions for production.
