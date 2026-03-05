# LiveSvelte Example Project

A working Phoenix application demonstrating LiveSvelte features — Svelte 5 components
integrated with Phoenix LiveView.

## Setup

1. Install Elixir + Node.js 19+
2. Run `mix setup` (installs deps + npm packages + creates DB)
3. Start server: `mix phx.server`
4. Visit: http://localhost:4000

## Demo Categories

### Basics
- **Hello World** (`/hello-world`) — Simplest component rendering
- **Struct Props** (`/live-struct`) — Passing Elixir structs as props (requires `@derive Jason.Encoder`)
- **Lodash** (`/lodash`) — Using npm packages in Svelte components

### Interactive
- **Counter** (`/live-simple-counter`) — Server state + client events
- **Plus/Minus (Live)** (`/live-plus-minus`) — LiveView event handling
- **Hybrid Counter** (`/live-plus-minus-hybrid`) — Mix of client and server events
- **Lights** (`/live-lights`) — Multiple components sharing LiveView state
- **Sigil** (`/live-sigil`) — Inline Svelte templates with the `~V` sigil

### Data & Real-Time
- **Streams** (`/streams`) — Phoenix `stream()` for efficient list updates
- **Props Diff** (`/live-props-diff`) — Only changed assigns sent on update (JSON Patch)
- **ID List Diff** (`/live-id-list-diff`) — ID-based list diffing for minimal ops
- **Chat** (`/live-chat`) — Real-time updates with PubSub + `pushEvent`
- **Log List** (`/live-log-list`) — Dynamic list updates
- **Breaking News** (`/live-breaking-news`) — Real-time ticker with `~V` sigil

### Slots
- **Simple Slots** (`/live-slots-simple`) — Basic slot usage
- **Dynamic Slots** (`/live-slots-dynamic`) — Named slots with dynamic content

### Composables
- **Form** (`/live-form`) — `useLiveForm()` with Ecto changeset validation
- **File Upload** (`/live-upload`) — `useLiveUpload()` with progress and validation
- **Navigation** (`/live-navigation`) — `useLiveNavigation()` for patch/navigate
- **Composition** (`/live-composition`) — `useLiveSvelte()` for pushEvent in component trees
- **Event Reply** (`/live-event-reply`) — `useEventReply()` for request-response

### Advanced
- **SSR Demo** (`/live-ssr`) — Server-side rendering with NodeJS (see SSR section below)
- **Client Loading** (`/live-client-side-loading`) — Loading slot shown until hydration

### Ecto
- **Notes OTP** (`/live-notes-otp`) — SQLite-backed notes with Ecto

## Testing

```bash
# Server-side tests (fast, no browser)
mix test --only phoenix_test

# Browser E2E tests (requires ChromeDriver)
mix test --only e2e

# All tests
mix test
```

**After changing JS/Svelte files**, rebuild before running tests:
```bash
mix assets.js && mix test
```

E2E tests require Chrome + ChromeDriver in PATH. Install with your OS package manager.
See `live_svelte/CLAUDE.md` for detailed testing guidance.

## SSR (Server-Side Rendering)

SSR is disabled by default in development. To enable:

**config/dev.exs:**
```elixir
config :live_svelte, ssr: true, ssr_module: LiveSvelte.SSR.ViteJS
```

**For production**, use NodeJS SSR (already configured):
```elixir
config :live_svelte, ssr: true, ssr_module: LiveSvelte.SSR.NodeJS
```

Build the SSR bundle before SSR works:
```bash
mix assets.js && mix compile
```

The SSR demo page (`/live-ssr`) uses `ssr={true}` on the component. NodeJS must be available for SSR in production; in test env SSR is disabled globally via `config :live_svelte, ssr: false`.

## Learn more

- LiveSvelte: https://github.com/woutdp/live_svelte
- Phoenix: https://hexdocs.pm/phoenix
