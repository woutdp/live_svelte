# Introduction

LiveSvelte brings end-to-end reactivity between [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) and [Svelte 5](https://svelte.dev/) components. Server state flows directly into Svelte components as reactive props, and user interactions in Svelte components push events back to the LiveView process — all over the existing Phoenix WebSocket.

## Three-Layer Architecture

LiveSvelte is built on three layers that work together:

```
LiveView (Elixir)     →   SvelteHook (Phoenix hook)   →   Svelte 5 (component)
server assigns              reads data attrs               reactive props
handle_event/3              pushEvent/handleEvent          $props(), $state()
```

1. **LiveView** renders an HTML wrapper div with JSON-encoded props in `data-props`. State lives on the server.
2. **SvelteHook** (a Phoenix LiveView JS hook) mounts and updates Svelte components. It reads `data-props` on mount and applies patches on update.
3. **Svelte 5 component** receives props via `$props()` and re-renders reactively whenever the server sends updates.

## Key Features

- **Full Svelte 5 support** — `$props()`, `$state()`, `$derived()`, runes syntax, snippets
- **Server-side rendering (SSR)** — Optional first-paint HTML via NodeJS (production) or ViteJS (development)
- **Efficient props diffing** — Three-tier system: change tracking → JSON Patch → ID-based list diffing
- **Phoenix Streams** — Native support for `stream()` with efficient patch operations
- **Composables** — `useLiveSvelte`, `useLiveEvent`, `useLiveConnection`, `useLiveNavigation`, `useLiveForm`, `useLiveUpload`, `useEventReply`
- **TypeScript** — Full type support across Elixir and JavaScript boundaries
- **Igniter installer** — One-command setup with `mix igniter.install live_svelte`
- **phoenix_vite + Vite** — [phoenix_vite](https://github.com/LostKobrakai/phoenix_vite) integrates Vite with Phoenix: one `mix phx.server` starts both the app and the Vite dev server (when the installer’s `config/dev.exs` is used), giving instant Svelte/CSS HMR and optimized production builds

## When to Use LiveSvelte

LiveSvelte is a good fit when you want:

- Rich, interactive UI components with real-time server state
- Svelte 5's reactive primitives and component model alongside LiveView's server logic
- Gradual adoption — mix `<.svelte>` components with regular HEEX templates

Plain LiveView may be sufficient when:

- Your UI interactions map naturally to LiveView events without needing local component state
- You don't need Svelte-specific features like `$derived()` or Svelte snippets

## Compatibility

| Dependency       | Version              |
|------------------|----------------------|
| LiveSvelte       | 0.17.4               |
| Svelte           | 5.x                  |
| Phoenix          | 1.7+ (1.8+ for Igniter installer) |
| Phoenix LiveView | 1.0+                 |
| Elixir           | 1.17+                |
| Node.js or Bun   | Node.js 19+ for SSR; Bun or Node.js 19+ for tooling |
