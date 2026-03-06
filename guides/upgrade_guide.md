# Upgrade Guide

## Upgrading to 0.18.0

Version 0.18.0 migrates the build toolchain from esbuild to Vite and removes
the `live_json` dependency. Follow the steps below to update your project.

### 1. Replace esbuild with Vite

#### `mix.exs` — swap deps

```elixir
# Remove:
{:esbuild, "~> 0.8", runtime: Mix.env() == :dev}

# Add:
{:phoenix_vite, "~> 0.4"}
```

Also remove any `config :esbuild` block from `config/config.exs`:

```elixir
# Remove entirely:
config :esbuild, :default,
  args: ~w(js/app.js --bundle ...),
  cd: Path.expand("../assets", __DIR__),
  env: %{"NODE_PATH" => ...}
```

Run `mix deps.get` after updating `mix.exs`.

#### `assets/package.json` — add Vite and Svelte plugin

```json
{
  "devDependencies": {
    "vite": "^6.0.0",
    "@sveltejs/vite-plugin-svelte": "^5.0.0",
    "@tailwindcss/vite": "^4.0.0"
  }
}
```

Run `npm install` (or `cd assets && npm install`) after updating.

#### Create `assets/vite.config.mjs`

Delete the old `assets/build.js` and create `assets/vite.config.mjs`:

```javascript
import { defineConfig } from "vite"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"
import tailwindcss from "@tailwindcss/vite"

export default defineConfig({
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
    cors: { origin: "http://localhost:4000" },
  },
  optimizeDeps: {
    include: ["live_svelte", "phoenix", "phoenix_html", "phoenix_live_view"],
  },
  ssr: { noExternal: process.env.NODE_ENV === "production" ? true : undefined },
  build: {
    manifest: false,
    ssrManifest: false,
    rollupOptions: { input: ["js/app.js", "css/app.css"] },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  plugins: [
    tailwindcss(),
    svelte({ compilerOptions: { css: "injected" } }),
    liveSveltePlugin({ entrypoint: "./js/server.js" }),
  ],
})
```

The `liveSveltePlugin` is exported from `live_svelte/vitePlugin` and handles
SSR component discovery automatically — no separate SSR build config is needed.

#### Update `config/dev.exs` — replace esbuild watcher with Vite

```elixir
# Remove from watchers:
esbuild: {Esbuild, :install_and_run, [:default, ~w(--bundle ...)]}

# Update the endpoint config block:
config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "...",
  # Assets are now served by the Vite dev server on port 5173:
  static_url: [host: "localhost", port: 5173],
  watchers: [
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    vite: {PhoenixVite.Npm, :run, [:vite, ~w(dev)]}
  ]
```

Setting `static_url` to the Vite dev server port is important — it ensures
LiveView generates asset URLs that point to the Vite dev server (which provides
HMR) rather than Phoenix's static file serving.

Add ViteJS SSR for development at the bottom of `config/dev.exs`. This means
new `.svelte` files are discovered automatically without needing to rebuild assets
after every addition:

```elixir
config :live_svelte, ssr_module: LiveSvelte.SSR.ViteJS, vite_host: "http://localhost:5173"
```

Production continues to use NodeJS SSR with the pre-built `priv/svelte/server.js`
(the default), so no production config change is needed.

#### Update `lib/my_app_web/endpoint.ex`

Import `PhoenixVite.Plug` and add the favicon plug. The favicon plug proxies the
browser favicon request to the Vite dev server in development:

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app
  import PhoenixVite.Plug  # <-- add this

  # ... socket declarations ...

  # Add before Plug.Static:
  plug :favicon, dev_server: {PhoenixVite.Components, :has_vite_watcher?, [__MODULE__]}

  plug Plug.Static,
    at: "/",
    from: :my_app,
    gzip: false,
    only: MyAppWeb.static_paths()

  # ... rest of plugs unchanged ...
end
```

#### Update `lib/my_app_web/components/layouts/root.html.heex`

Replace the static asset tags with `PhoenixVite.Components.assets`. This single
component handles both development (proxying to the Vite dev server with HMR)
and production (emitting hashed `<script>`/`<link>` tags from the Vite manifest):

```heex
<%# Remove: %>
<link rel="stylesheet" href={~p"/assets/app.css"} />
<script defer src={~p"/assets/app.js"}></script>

<%# Replace with: %>
<PhoenixVite.Components.assets
  names={["js/app.js", "css/app.css"]}
  manifest={{:my_app, "priv/static/.vite/manifest.json"}}
  dev_server={PhoenixVite.Components.has_vite_watcher?(MyAppWeb.Endpoint)}
  to_url={fn p -> static_url(@conn, p) end}
/>
```

Replace `:my_app` and `MyAppWeb.Endpoint` with your own OTP app name and
endpoint module.

### 2. Remove live_json (if used)

Remove the dependency from `mix.exs`:

```elixir
# Remove:
{:live_json, "~> 0.4"}
```

In your LiveViews, replace the `live_json_props` attribute with the standard
`props` attribute. Props diffing via JSON Patch is enabled by default in 0.18.0,
so payloads remain optimized — only changed values are sent over the wire:

```heex
<%# Before: %>
<.svelte name="MyComponent" live_json_props={@json_props} socket={@socket} />

<%# After: %>
<.svelte name="MyComponent" props={@my_props} socket={@socket} />
```

If you want to disable props diffing globally (not recommended):

```elixir
# config/config.exs
config :live_svelte, enable_props_diff: false
```

### 3. Verify the upgrade

After completing the steps above:

```bash
mix deps.get
cd assets && npm install && cd ..
mix phx.server   # Should start Phoenix + Vite dev server together
mix test         # Library unit tests
cd example_project && mix assets.build && mix test --only phoenix_test
```
