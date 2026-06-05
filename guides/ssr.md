# Server-Side Rendering

LiveSvelte supports server-side rendering (SSR) of Svelte components, which provides meaningful HTML on the first paint before the JavaScript bundle loads.

## How SSR Works

When SSR is active, the initial (dead) render calls Node.js to execute Svelte's `render()` function server-side. The result is embedded directly in the HTML response:

1. LiveSvelte calls `SSR.render(component_name, props, slots)`
2. `render()` returns `%{"head" => "<style>...</style>", "html" => "<div>...</div>", "css" => %{"code" => "..."}}`
3. The `head` and CSS styles are included in the page; `html` is placed inside the `data-svelte-target` div
4. When JavaScript loads, the `SvelteHook` hydrates the existing DOM instead of mounting fresh

## SSR Modes

LiveSvelte has three SSR modules for different environments:

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
mix assets.build  # runs phoenix_vite.npm vite build (client + SSR)
```

This produces `priv/svelte/server.js`, which the NodeJS supervisor loads on application start.

### Deno Mode (Production)

Uses [`deno_rider`](https://github.com/aglundahl/deno_rider) to run a Deno process that executes the SSR bundle. This is an alternative to NodeJS mode for applications already running Deno.

Add `deno_rider` to your dependencies:

```elixir
# mix.exs
{:deno_rider, "~> 0.2.0"}
```

```elixir
# config/prod.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.Deno,
  ssr: true
```

Start the DenoRider process in your application supervisor:

```elixir
# lib/my_app/application.ex
children = [
  {DenoRider, [main_module_path: LiveSvelte.SSR.Deno.server_path() <> "/server.js"]},
  ...
]
```

The SSR bundle at `priv/svelte/server.js` is built the same way as for NodeJS mode:

```bash
mix assets.build
```

> #### Linux glibc requirement {: .warning}
>
> The precompiled `deno_rider` binaries require glibc >= 2.38 on Linux. This may not be available on older distributions (e.g. Ubuntu 22.04 ships glibc 2.35). Check your version with `ldd --version`.

## Switching SSR Adapter

If you installed LiveSvelte with the default Node.js adapter and want to switch to Deno (or back), use the `live_svelte.migrate` Igniter task instead of editing files manually:

```bash
mix live_svelte.migrate --ssr-node-to-deno
mix live_svelte.migrate --ssr-deno-to-node
```

Each command updates `prod.exs`, `application.ex`, and `assets/js/server.js`. You will be asked before any dependency is removed, and reminded to run `mix deps.get` afterwards.

> #### Requires Igniter {: .info}
>
> Install Igniter if it is not already a dependency: `mix igniter.install igniter`.

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
config :live_svelte, ssr_module: LiveSvelte.SSR.Deno     # production (Deno)
```

## Per-Component SSR Opt-Out

Disable SSR for a specific component:

```heex
<.svelte name="HeavyChart" props={%{data: @data}} socket={@socket} ssr={false} />
```

Components with `ssr={false}` render a loading slot or nothing on the first paint, then mount client-side normally.

## HMR in Development

When running with `LiveSvelte.SSR.ViteJS`, changes to Svelte files trigger automatic hot module replacement. The `SvelteHook` re-mounts affected components without a full page reload.

**With phoenix_vite (recommended):** The layout uses `PhoenixVite.Components.assets`. The Igniter installer adds to your endpoint in `config/dev.exs` a `:vite` watcher and `static_url: [host: "localhost", port: 5173]`, so `mix phx.server` starts the Vite dev server and asset URLs point at it — Svelte and CSS then hot-reload with no extra terminal. See [Installation](installation.md) for the exact config; if you added phoenix_vite or LiveSvelte manually, add that endpoint config yourself.

**Without phoenix_vite:** Use `LiveSvelte.Reload.vite_assets/1` in your layout to include Vite's HMR client and production fallback:

```heex
<LiveSvelte.Reload.vite_assets assets={["/js/app.js"]}>
  <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
  <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
</LiveSvelte.Reload.vite_assets>
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
