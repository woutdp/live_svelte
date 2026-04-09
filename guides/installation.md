# Installation

LiveSvelte uses [Vite](https://vitejs.dev/) for both client and SSR builds, replacing the default `esbuild` setup in Phoenix projects.

## Prerequisites

- **Node.js 19+ or Bun** — for package management and Vite builds. Production SSR (when using `LiveSvelte.SSR.NodeJS`) still requires Node.js 19+ on the server.
- **Elixir 1.17+**
- **Phoenix 1.8+** — required for the Igniter installer
- **Igniter** — the installation scaffolding tool

## Quick Start (Recommended)

### Step 1: Install the Igniter archive

```bash
mix archive.install hex igniter_new
```

### Step 2: Add LiveSvelte to your project

For an **existing** Phoenix 1.8+ project:

```bash
mix igniter.install live_svelte
```

For a **new** project with LiveSvelte pre-installed:

```bash
mix igniter.new my_app --with phx.new --install live_svelte
```

#### Using Bun

To use **Bun** instead of Node.js/npm for package management and Vite:

- **Existing project:** `mix igniter.install live_svelte --bun`
- **New project:** `mix igniter.new my_app --with phx.new --install live_svelte --bun`

After install, `mix assets.setup` and `mix assets.build` use Bun (e.g. `bun install`, phoenix_vite's Bun task) instead of npm.

### Step 3: Install JS dependencies and build

```bash
mix assets.setup    # phoenix_vite.npm assets install (or: mix setup)
mix assets.build
mix phx.server
```

Visit `/svelte_demo` to verify the installation with the generated demo component.

## What the Installer Does

Running `mix igniter.install live_svelte` makes the following changes to your project:

**`package.json`** (at project root) — the installer moves it from `assets/` and adds:
- `live_svelte`, `phoenix_vite: "file:./deps/phoenix_vite"` (dev), and Svelte-related deps

**`config/config.exs`** — adds `config :phoenix_vite, PhoenixVite.Npm, ...` (when using `--bun`, the installer configures `PhoenixVite.Bun` and Bun-based aliases instead).

**`assets/vite.config.mjs`** — adds the Svelte plugin, `liveSveltePlugin`, and `ssr: { noExternal: ... }`. A single config is used for both client and SSR builds (no separate `vite.ssr.config.js`); the SSR build is run via `phoenix_vite.npm vite build --ssr js/server.js --outDir ../priv/svelte`.

**`assets/js/app.js`** — adds hook wiring:
```js
import { getHooks } from "live_svelte"
import Components from "virtual:live-svelte-components"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: getHooks(Components),
  // ...
})
```

**`lib/app_web.ex`** — adds `import LiveSvelte` to `html_helpers`

**`lib/app/application.ex`** — adds a conditional NodeJS supervisor that only starts in production (where `ssr_module` is `LiveSvelte.SSR.NodeJS`):
```elixir
node_js_children =
  if Application.get_env(:live_svelte, :ssr_module, nil) == LiveSvelte.SSR.NodeJS do
    [{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}]
  else
    []
  end

children = node_js_children ++ [...]
```

**`config/config.exs`** — base SSR config:
```elixir
config :live_svelte, ssr: true
```

**`config/dev.exs`** — the installer composes `phoenix_vite.install` first, which adds to your **endpoint** the Vite dev server watcher and `static_url` so that assets and HMR are served from Vite (port 5173). LiveSvelte then adds the `live_svelte` app config. Together this gives you instant Svelte/CSS HMR when you run `mix phx.server`:

```elixir
# From phoenix_vite.install (required for HMR):
config :my_app, MyAppWeb.Endpoint,
  static_url: [host: "localhost", port: 5173],
  watchers: [
    vite: {PhoenixVite.Npm, :run, [:vite, ~w(dev)]}
  ]

# From live_svelte.install (development SSR):
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

If you add LiveSvelte or phoenix_vite **manually** (e.g. without running the Igniter installer), you must add the endpoint’s `static_url` and `:vite` watcher to `config/dev.exs` yourself; otherwise the layout will serve built assets and Svelte changes will not hot-reload.

**`config/prod.exs`** — production SSR via NodeJS:
```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

**`mix.exs`** — adds phoenix_vite-driven aliases: `assets.setup`, `assets.build` (client + SSR via `phoenix_vite.npm vite build`):
```elixir
"assets.setup": ["phoenix_vite.npm assets install"],
"assets.build": [
  "phoenix_vite.npm vite build --manifest --emptyOutDir true",
  "phoenix_vite.npm vite build --ssrManifest --emptyOutDir false --ssr js/server.js --outDir ../priv/svelte"
]
```

**`assets/svelte/`** — creates the Svelte components directory with a demo component

**`assets/css/app.css`** — adds `@source "../svelte/**/*.svelte";` if Tailwind is present (a bare directory path does not include `.svelte` files by default)

**`.gitignore`** — adds `/assets/svelte/_build/` and `/priv/svelte/`

> #### Phoenix Version Requirement {: .warning}
>
> The Igniter installer requires **Phoenix 1.8+**. The library itself works with Phoenix 1.7+ when installed manually.

## Manual Installation

> #### Manual Installation Not Recommended {: .warning}
>
> Manual installation steps are complex and kept out-of-date as dependencies evolve. We strongly recommend using `mix igniter.install live_svelte` instead.

If you must install manually (e.g. Phoenix < 1.8), follow the **Option B — Manual installation** steps in the [README](https://github.com/woutdp/live_svelte#option-b--manual-installation). Those steps are the authoritative reference and kept up to date.

#### Using Bun with manual installation

To use **Bun** instead of npm when installing manually:

1. Add the optional dependency in `mix.exs`: `{:bun, ">= 1.5.1 and < 2.0.0-0"}`
2. In `config/config.exs`, use `config :phoenix_vite, PhoenixVite.Bun, ...` (with the same options you would use for `PhoenixVite.Npm`; see [phoenix_vite](https://hexdocs.pm/phoenix_vite) for the Bun API).
3. In `mix.exs` aliases, use `phoenix_vite.bun` instead of `phoenix_vite.npm`:
   - `"assets.setup": ["phoenix_vite.bun assets install"]`
   - `"assets.build"`: same two `phoenix_vite.bun vite build ...` commands as in the npm version.
4. In `config/dev.exs` watchers, use `vite: {PhoenixVite.Bun, :run, [:vite, ~w(dev)]}`.

Production SSR still uses Node.js (`LiveSvelte.SSR.NodeJS`); the server must have Node.js 19+ installed.

## Disabling SSR

If you don't need server-side rendering, disable it globally:

```elixir
# config/config.exs
config :live_svelte, ssr: false
```

Or per-component:

```heex
<.svelte name="Counter" props={%{count: @count}} socket={@socket} ssr={false} />
```

## Next Steps

- [Basic Usage](basic_usage.md) — your first `<.svelte>` component
- [Configuration](configuration.md) — all config options
