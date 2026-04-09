# Upgrade Guide

## Upgrading to 0.18.0

Version 0.18.0 migrates the build toolchain from esbuild to Vite and removes
the `live_json` dependency. Follow the steps below to update your project.

### 1. Replace esbuild with Vite

#### `mix.exs` — swap deps and update aliases

Remove `:esbuild` (and `:tailwind` if present), add `phoenix_vite`:

```elixir
defp deps do
  [
    # Remove: {:esbuild, ...}
    # Remove: {:tailwind, ...}  # if present
    {:live_svelte, "~> 0.18"},
    {:phoenix_vite, "~> 0.4"},
    # ... rest of deps unchanged
  ]
end
```

Replace the esbuild/tailwind aliases with the two-step Vite build:

```elixir
defp aliases do
  [
    # Remove: "assets.setup": ["esbuild.install --if-missing", ...]
    # Remove: "assets.build": ["esbuild ...", "tailwind ...", ...]
    "assets.setup": ["phoenix_vite.npm assets install"],
    "assets.build": [
      "phoenix_vite.npm vite build --manifest --emptyOutDir true",
      "phoenix_vite.npm vite build --ssrManifest --emptyOutDir false --ssr js/server.js --outDir ../priv/svelte"
    ],
    "assets.deploy": ["assets.build", "phx.digest"],
    # ... rest of aliases unchanged
  ]
end
```

Run `mix deps.get` after updating `mix.exs`.

#### `package.json` — create at the project root (not in `assets/`)

If you had `assets/package.json`, delete it and create `package.json` at the
project root. With Tailwind, include the `@tailwindcss/vite` packages:

```json
{
  "type": "module",
  "dependencies": {
    "live_svelte": "file:./deps/live_svelte",
    "phoenix": "file:./deps/phoenix",
    "phoenix_html": "file:./deps/phoenix_html",
    "phoenix_live_view": "file:./deps/phoenix_live_view",
    "topbar": "^3.0.0"
  },
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "^7.0.0",
    "phoenix_vite": "file:./deps/phoenix_vite",
    "svelte": "^5.0.0",
    "vite": "^8.0.0",
    "@tailwindcss/vite": "^4.1.0",
    "tailwindcss": "^4.1.0"
  }
}
```

_Without Tailwind, omit the last two `@tailwindcss/vite` and `tailwindcss` entries._

Also update `.gitignore` — since `package.json` is now at the project root,
`node_modules` lives there too:

```
# Remove: /assets/node_modules
# Add:
node_modules
```

#### `assets/vite.config.mjs` — create (or replace old config)

Delete `assets/build.js` if it exists, then create `assets/vite.config.mjs`:

```javascript
import { defineConfig } from "vite"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"
// With Tailwind: add this import
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
  // Required for Phoenix 1.8+ colocated JS hooks
  resolve: {
    alias: {
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  plugins: [
    tailwindcss(), // With Tailwind: include this; remove if not using Tailwind
    svelte({ compilerOptions: { css: "injected" } }),
    liveSveltePlugin({ entrypoint: "./js/server.js" }),
  ],
})
```

#### `assets/js/server.js` — create

```javascript
import { getRender } from "live_svelte"
import Components from "virtual:live-svelte-components"
export const render = getRender(Components)
```

#### `assets/js/app.js` — update hooks and topbar import

Change the topbar import from the vendor path to the npm package:

```javascript
// Before:
import topbar from "../vendor/topbar"
// After:
import topbar from "topbar"
```

Add the LiveSvelte hooks:

```javascript
import {getHooks} from "live_svelte"
import Components from "virtual:live-svelte-components"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...colocatedHooks, ...getHooks(Components)},
  // ...
})
```

_If your app doesn't use colocated hooks (older Phoenix), use `hooks: {...getHooks(Components)}`._

#### `config/config.exs` — replace esbuild/tailwind config with phoenix_vite

```elixir
# Remove entirely:
# config :esbuild, :default, ...
# config :tailwind, :default, ...  # if present

# Add:
config :phoenix_vite, PhoenixVite.Npm,
  assets: [args: [], cd: Path.expand("..", __DIR__)],
  vite: [
    args: ~w(exec -- vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

config :live_svelte, ssr: true
```

#### `config/dev.exs` — replace esbuild/tailwind watchers with Vite

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ... existing config ...
  # Assets are now served by the Vite dev server on port 5173:
  static_url: [host: "localhost", port: 5173],
  watchers: [
    # Remove: esbuild: {...}
    # Remove: tailwind: {...}  # if present — Vite handles Tailwind now
    vite: {PhoenixVite.Npm, :run, [:vite, ~w(dev)]}
  ]

config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

#### `config/prod.exs` — add NodeJS SSR

```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

#### `lib/my_app_web/endpoint.ex` — add PhoenixVite.Plug

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app
  import PhoenixVite.Plug  # <-- add this

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

#### `lib/my_app_web/components/layouts/root.html.heex` — use Vite-aware assets

Replace the static asset tags:

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

#### `lib/my_app/application.ex` — add NodeJS.Supervisor for production SSR

```elixir
def start(_type, _args) do
  node_js_children =
    if Application.get_env(:live_svelte, :ssr_module, nil) == LiveSvelte.SSR.NodeJS do
      [{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}]
    else
      []
    end

  children = node_js_children ++ [
    # ... your existing children
  ]
  # ...
end
```

#### `assets/css/app.css` — update Tailwind config (if using Tailwind)

Replace the old Tailwind v3 `@tailwind` directives with Tailwind v4 syntax and
add the Svelte source glob. A bare directory path (`@source "../svelte"`) does
not include `.svelte` files — the explicit glob is required:

```css
/* Remove: */
/* @tailwind base; */
/* @tailwind components; */
/* @tailwind utilities; */

/* Add: */
@import "tailwindcss";
@source "../svelte/**/*.svelte";
```

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

```bash
mix deps.get
mix assets.setup     # npm install from project root
mix assets.build     # two-step Vite build (client + SSR)
mix phx.server       # Phoenix + Vite dev server start together
```

Visit your app — Svelte components should render with HMR working in
development and SSR working in both environments.
