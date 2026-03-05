# Deployment

Deploying a LiveSvelte application requires Node.js on the server for SSR (server-side rendering). This guide covers the production build process and deployment considerations.

## Requirements

- **Node.js 19+** on the production server (for `LiveSvelte.SSR.NodeJS`). If you use Bun for local builds, the production server still needs Node.js 19+ for SSR (the SSR bundle is run by Node.js).
- Standard Phoenix/Elixir deployment tooling (releases, Docker, etc.)

## Build Steps

```bash
# 1. Build client bundle and SSR bundle
mix assets.build

# 2. Compile application (copies SSR bundle to _build)
mix compile

# OR in a single release command:
MIX_ENV=prod mix assets.build && MIX_ENV=prod mix release
```

### What `mix assets.build` Does

The `assets.build` alias runs (in order):

1. `phoenix_vite.npm vite build --manifest --emptyOutDir true` — client bundle (and CSS when using Tailwind via Vite) to `priv/static/`
2. `phoenix_vite.npm vite build --ssrManifest ... --ssr js/server.js --outDir ../priv/svelte` — SSR bundle to `priv/svelte/server.js`

> The same `assets/vite.config.mjs` is used for both builds; phoenix_vite runs the second command with different CLI flags.

## NodeJS Supervisor

The Igniter installer adds `NodeJS.Supervisor` to your `application.ex`:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... other children ...
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

`LiveSvelte.SSR.NodeJS.server_path/0` returns the path to `priv/svelte/server.js`, which is the SSR bundle.

Adjust `pool_size` based on expected SSR load. A pool of 4 workers is a reasonable default.

## Production Config

```elixir
# config/prod.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

## SSR Bundle

The SSR bundle (`priv/svelte/server.js`) is:
- Built via the same `assets/vite.config.mjs` with `--ssr js/server.js --outDir ../priv/svelte`
- Fully self-contained (all dependencies bundled, `ssr: { noExternal: true }`)
- Required to be present at application start when `ssr_module: LiveSvelte.SSR.NodeJS`

After `mix assets.build`, `mix compile` copies `priv/svelte/server.js` into `_build/`. This copy in `_build/` is what NodeJS.Supervisor actually loads at runtime.

> #### Always Compile After Building SSR Bundle {: .info}
>
> After `mix assets.build`, run `mix compile` so `_build/` gets the updated SSR bundle. In a CI/CD pipeline, ensure both steps run.

## Docker Deployment

Include Node.js in your Docker image:

```dockerfile
# Multi-stage build example
FROM node:20-slim AS assets-builder
WORKDIR /app
COPY assets/ assets/
COPY deps/ deps/
RUN cd assets && npm install
RUN mix assets.build

FROM elixir:1.17-slim AS release-builder
# ... standard Elixir release steps ...
RUN mix release

FROM elixir:1.17-slim
# Include Node.js for SSR
RUN apt-get update && apt-get install -y nodejs npm
COPY --from=release-builder /app/_build/prod/rel/my_app ./
CMD ["/app/bin/my_app", "start"]
```

A simpler approach is to use an image that includes both Elixir and Node.js:

```dockerfile
FROM hexpm/elixir:1.17.3-erlang-27.1.2-debian-bookworm-20241016-slim
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs
```

## Disabling SSR in Production

If you choose not to use SSR (e.g. to avoid Node.js on the server), disable it globally and remove `NodeJS.Supervisor`:

```elixir
# config/prod.exs
config :live_svelte, ssr: false
```

Remove `NodeJS.Supervisor` from `application.ex` children. The `{:nodejs, "~> 3.1"}` dependency can remain in `mix.exs` but won't be used.

## Per-Component SSR Opt-Out

Even with global SSR enabled, you can disable SSR for expensive components to reduce Node.js load:

```heex
<.svelte name="HeavyVisualization" props={%{data: @data}} socket={@socket} ssr={false} />
```

Use SSR primarily for above-the-fold content where first-paint HTML matters.

## Telemetry for Observability

Attach SSR telemetry handlers to monitor production performance:

```elixir
:telemetry.attach_many(
  "live-svelte-ssr-metrics",
  [
    [:live_svelte, :ssr, :stop],
    [:live_svelte, :ssr, :exception]
  ],
  fn
    [:live_svelte, :ssr, :stop], measurements, _meta, _ ->
      MyApp.Metrics.histogram("live_svelte.ssr.duration", measurements.duration_microseconds)
    [:live_svelte, :ssr, :exception], _measurements, meta, _ ->
      Logger.error("SSR failed: #{inspect(meta.reason)}")
  end,
  nil
)
```

## Upgrading

When upgrading LiveSvelte versions:

1. Update `{:live_svelte, "~> x.y"}` in `mix.exs`
2. Run `mix deps.get`
3. Check `CHANGELOG.md` for breaking changes
4. Rebuild: `mix assets.build && mix compile`
5. Run tests: `mix test`
