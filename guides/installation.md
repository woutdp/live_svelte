# Installation

LiveSvelte uses [Vite](https://vitejs.dev/) for both client and SSR builds, replacing the default `esbuild` setup in Phoenix projects.

## Prerequisites

- **Node.js 19+** — required for SSR (server-side rendering)
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

Use the `--bun` flag to use `bun` instead of `npm`:

```bash
mix igniter.install live_svelte --bun
```

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

**`config/config.exs`** — adds `config :phoenix_vite, PhoenixVite.Npm, ...`

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

**`lib/app/application.ex`** — adds NodeJS supervisor for production SSR:
```elixir
{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}
```

**`config/config.exs`** — base SSR config:
```elixir
config :live_svelte, ssr: true
```

**`config/dev.exs`** — development SSR via Vite dev server:
```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

**`config/prod.exs`** — production SSR via NodeJS:
```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

**`mix.exs`** — adds phoenix_vite-driven aliases: `assets.setup`, `assets.build` (client + SSR via `phoenix_vite.npm vite build`):
```elixir
"assets.setup": ["phoenix_vite.npm assets install", "tailwind.install --if-missing"],
"assets.build": [
  "phoenix_vite.npm vite build --manifest --emptyOutDir true",
  "phoenix_vite.npm vite build --ssrManifest --emptyOutDir false --ssr js/server.js --outDir ../priv/svelte"
]
```

**`assets/svelte/`** — creates the Svelte components directory with a demo component

**`assets/app.css`** — adds `@source "../svelte";` if Tailwind is present

**`.gitignore`** — adds `/assets/svelte/_build/` and `/priv/svelte/`

> #### Phoenix Version Requirement {: .warning}
>
> The Igniter installer requires **Phoenix 1.8+**. The library itself works with Phoenix 1.7+ when installed manually.

## Manual Installation

> #### Manual Installation Not Recommended {: .warning}
>
> Manual installation steps are complex and kept out-of-date as dependencies evolve. We strongly recommend using `mix igniter.install live_svelte` instead.

If you must install manually (e.g. Phoenix < 1.8), the overall steps mirror the LiveVue manual installation process:

1. Add `{:live_svelte, "~> 0.17"}` to `mix.exs` deps
2. Configure Vite with the Svelte plugin and `liveSveltePlugin`
3. Create `vite.ssr.config.js`
4. Wire up `getHooks(Components)` in `app.js`
5. Add `import LiveSvelte` to `html_helpers`
6. Add `NodeJS.Supervisor` to `application.ex`
7. Configure SSR in `config/`

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
