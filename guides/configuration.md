# Configuration

All LiveSvelte configuration is set via `Application.put_env(:live_svelte, key, value)` in your config files.

## Application Config Keys

| Key | Default | Description |
|-----|---------|-------------|
| `:ssr` | `true` | Enable server-side rendering globally |
| `:ssr_module` | `LiveSvelte.SSR.NodeJS` | SSR module: `NodeJS` or `ViteJS` |
| `:json_library` | `LiveSvelte.JSON` | JSON encoder (e.g. `Jason`) |
| `:enable_props_diff` | `true` | Enable three-tier props diffing system |
| `:gettext_backend` | `nil` | Gettext module for form error translation |
| `:vite_host` | `"http://localhost:5173"` | Vite dev server URL (used by ViteJS SSR mode) |

## Typical Configuration by Environment

### `config/config.exs` (base)

```elixir
config :live_svelte, ssr: true
```

### `config/dev.exs` (development)

```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

### `config/prod.exs` (production)

```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

### `config/test.exs` (test)

```elixir
# SSR is off in tests by default (NodeJS not started in test env)
config :live_svelte, ssr: false
```

## Per-Component Attributes

These `<.svelte>` component attributes override global config for individual components:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | **required** | Svelte component filename (without `.svelte`) |
| `props` | `map` | `%{}` | Props passed to the component |
| `socket` | `map` | `nil` | LiveView socket — required when `ssr: true` |
| `id` | `string` | auto | Stable DOM id override |
| `key` | `any` | `nil` | Identity key for DOM id in loops |
| `class` | `string` | `nil` | CSS class for the wrapper div |
| `ssr` | `boolean` | `true` | Enable SSR for this component |
| `diff` | `boolean` | `true` | Enable props diffing for this component |

### Examples

```heex
<!-- Disable SSR for a heavy chart component -->
<.svelte name="HeavyChart" props={%{data: @data}} socket={@socket} ssr={false} />

<!-- Disable props diffing (always send full props) -->
<.svelte name="SimpleDisplay" props={%{label: @label}} socket={@socket} diff={false} />

<!-- Stable id for components in loops -->
<.svelte name="Item" props={%{id: item.id, title: item.title}} socket={@socket} key={item.id} />
```

## Vite Plugin Options

Configure the `liveSveltePlugin` in `assets/vite.config.mjs`:

```js
import { liveSveltePlugin } from "live_svelte/vitePlugin"

export default defineConfig({
  plugins: [
    svelte(),
    liveSveltePlugin({
      // Options (all optional):
      paths: ["assets/svelte"],        // Directories to scan for .svelte files
      entrypoint: "assets/js/app.js"  // Main app entry point
    })
  ]
})
```

### Default Paths

By default, `liveSveltePlugin` discovers Svelte components in:
- `assets/svelte/**/*.svelte`
- `lib/**/*.svelte` (for colocated components next to LiveView modules)

## JSON Library

By default, LiveSvelte uses its own JSON encoder which handles `LiveSvelte.Encoder` protocol automatically. To use `Jason` instead:

```elixir
config :live_svelte, json_library: Jason
```

When using an external JSON library, LiveSvelte still runs all values through `LiveSvelte.Encoder` before passing to the library.

## Props Diffing

Props diffing is enabled by default. To disable globally:

```elixir
config :live_svelte, enable_props_diff: false
```

When disabled, LiveSvelte always sends the full props map on every update. This can be useful for debugging or for very simple UIs where diffing overhead is not worth it.

The three tiers (change tracking → JSON Patch → ID-based list diffing) are all part of the same system and toggle together.

## Gettext Integration

To translate Ecto changeset error messages using your Gettext backend:

```elixir
config :live_svelte, gettext_backend: MyAppWeb.Gettext
```

This affects `useLiveForm` — error messages shown in `field().error` will use translated strings from your `priv/gettext/` directory.
