# API Reference

Complete reference for all public LiveSvelte APIs.

## Elixir API

### `LiveSvelte.svelte/1`

Renders a Svelte component in a LiveView template.

```heex
<.svelte name="Counter" props={%{count: @count}} socket={@socket} />
```

**Attributes:**

| Attribute | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `name` | `string` | — | ✓ | Component name (filename without `.svelte`, relative to `assets/svelte/`) |
| `props` | `map` | `%{}` | | Props to pass to the component |
| `socket` | `map` | `nil` | | LiveView socket — required when `ssr: true` |
| `id` | `string` | auto | | Stable DOM id override |
| `key` | `any` | `nil` | | Identity key for DOM id generation in loops |
| `class` | `string` | `nil` | | CSS class on the wrapper div |
| `ssr` | `boolean` | `true` | | Enable SSR for this component |
| `diff` | `boolean` | `true` | | Enable props diffing (requires `enable_props_diff: true` in config) |
| `:loading` slot | | | | Content shown while component loads (only with `ssr={false}`) |
| `:inner_block` slot | | | | Inner content (passed to Svelte as a slot) |

**Name examples:**
```
Counter.svelte          → name="Counter"
forms/UserForm.svelte   → name="forms/UserForm"
```

---

### `~V` Sigil

Inline Svelte template as a LiveView render macro.

```elixir
def render(assigns) do
  ~V"""
  <script>
    let { count } = $props()
  </script>
  <p>Count: {count}</p>
  """
end
```

All LiveView assigns are automatically available as props. The template is written to `assets/svelte/_build/MyModule.svelte` at compile time.

---

### `LiveSvelte.Components`

Auto-generated shorthand component functions based on discovered `.svelte` files.

```elixir
# In web module html_helpers:
use LiveSvelte.Components

# In templates — instead of <.svelte name="Counter" ...>:
<.Counter count={@count} socket={@socket} />
```

`Counter.svelte` → `<.Counter>`, `forms/UserForm.svelte` → `<.forms_UserForm>` (slashes converted to underscores).

---

### `LiveSvelte.Test.get_svelte/1,2`

Inspect Svelte component props from HTML in tests.

```elixir
import LiveSvelte.Test

# Get first component in HTML
component = get_svelte(html)

# Get component by name
component = get_svelte(html, name: "Counter")

# Get component by DOM id
component = get_svelte(html, id: "Counter-1")

# Get directly from a LiveView
{:ok, view, _html} = live(conn, "/counter")
component = get_svelte(view, name: "Counter")
```

Returns a map with:
- `name` — component name string
- `id` — DOM id of the wrapper element
- `props` — decoded props map (string keys)
- `slots` — map of slot name → HTML string
- `ssr` — boolean, whether SSR was active

**Example:**
```elixir
{:ok, _view, html} = live(conn, "/counter")
component = get_svelte(html, name: "Counter")
assert component.props["count"] == 0
```

---

### `LiveSvelte.Encoder` Protocol

Protocol for encoding custom structs as JSON props. Implement it directly or use `@derive`:

```elixir
# Simple derive — exposes all public fields
@derive LiveSvelte.Encoder
defstruct [:id, :name]

# Restricted derive — only expose listed fields
@derive {LiveSvelte.Encoder, only: [:id, :name, :email]}
defstruct [:id, :name, :email, :password_hash]

# Excluded fields derive
@derive {LiveSvelte.Encoder, except: [:password_hash]}
defstruct [:id, :name, :email, :password_hash]
```

Without `@derive`, passing a struct as a prop will raise an error.

---

### `LiveSvelte.Reload` / `vite_assets/1`

When using the Igniter installer with phoenix_vite, the layout uses `PhoenixVite.Components.assets` instead. Use `LiveSvelte.Reload.vite_assets/1` when not using phoenix_vite (e.g. manual setup).

HMR helper for development. Includes the Vite dev server client script.

```heex
<!-- In root layout, development only -->
<%= if Application.get_env(:live_svelte, :ssr_module) == LiveSvelte.SSR.ViteJS do %>
  <LiveSvelte.Reload.vite_assets path="/assets/js/app.js" />
<% end %>
```

---

## JavaScript API

### `getHooks(Components)`

Entry point. Returns a hooks map to pass to `LiveSocket`:

```ts
import { getHooks } from "live_svelte"
import Components from "virtual:live-svelte-components"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: getHooks(Components),
  params: { _csrf_token: csrfToken }
})
```

---

### `useLiveSvelte()`

Access the Phoenix hook context from any LiveSvelte-mounted component.

```ts
import { useLiveSvelte } from "live_svelte"
```

```svelte
<script>
  import { useLiveSvelte } from "live_svelte"

  const { pushEvent, pushEventTo, live } = useLiveSvelte()

  function save(data) {
    pushEvent("save", data)
  }

  function saveWithReply(data) {
    pushEvent("save", data, (reply) => console.log(reply))
  }
</script>
```

**Returns:**
- `live` — raw Phoenix hook context
- `pushEvent(event, payload, callback?)` — push event to LiveView
- `pushEventTo(target, event, payload, callback?)` — push event to specific LiveView

---

### `useLiveEvent(event, callback)`

Subscribe to a server-sent LiveView event. Automatically cleans up on component destroy.

```svelte
<script>
  import { useLiveEvent } from "live_svelte"

  useLiveEvent("item_added", (payload) => {
    console.log("New item:", payload)
  })
</script>
```

---

### `useLiveConnection()`

Reactive WebSocket connection state.

```svelte
<script>
  import { useLiveConnection } from "live_svelte"

  const conn = useLiveConnection()
</script>

{#if !conn.connected}
  <div class="banner">Reconnecting...</div>
{/if}
```

**Returns:**
- `connected` — `boolean`, reactive

---

### `useLiveNavigation()`

Client-side LiveView navigation.

```svelte
<script>
  import { useLiveNavigation } from "live_svelte"

  const { patch, navigate } = useLiveNavigation()
</script>

<button onclick={() => patch("?page=2")}>Next page</button>
<button onclick={() => navigate("/other")}>Navigate</button>
```

**Returns:**
- `patch(hrefOrParams, opts?)` — patch current LiveView (triggers `handle_params/3`)
- `navigate(href, opts?)` — navigate to a new LiveView

Both accept `{ replace: true }` to use `history.replaceState`.

---

### `useLiveForm(formFn, opts?)`

Reactive form binding with Ecto changeset support. See [Forms and Validation](forms.md) for full documentation.

```ts
import { useLiveForm } from "live_svelte"
```

```svelte
<script>
  import { useLiveForm } from "live_svelte"
  let { form } = $props()
  const { field, fieldArray } = useLiveForm(() => form)
</script>
```

**Parameters:**
- `formFn` — getter function returning the form prop
- `opts?` — `{ changeEvent?, submitEvent?, debounceInMilliseconds? }`

**Returns:**
- `field(name)` — field descriptor with `name`, `value`, `error`, `phx-debounce`
- `fieldArray(name)` — array field with `fields`, `append`, `prepend`, `remove`

---

### `useLiveUpload(uploadConfig, options)`

File upload integration. See [File Uploads](uploads.md) for full documentation.

```ts
import { useLiveUpload } from "live_svelte"
```

```svelte
<script>
  import { useLiveUpload } from "live_svelte"
  let { uploads } = $props()
  const { showFilePicker, entries, submit, cancel, sync } = useLiveUpload(
    uploads.avatar,
    { changeEvent: "validate", submitEvent: "submit" }
  )
  $effect(() => sync(uploads.avatar))
</script>
```

**Parameters:**
- `uploadConfig` — the upload config object (e.g. `uploads.avatar`), passed directly not as a getter
- `options` — `{ changeEvent?: string, submitEvent: string }` — `submitEvent` is required

**Returns:**
- `showFilePicker()` — open file picker dialog
- `addFiles(files)` — enqueue files from `File[]` or `DataTransfer` (drag-drop)
- `entries` — `Readable<UploadEntry[]>` store — use `$entries` in templates
- `progress` — `Readable<number>` — overall progress 0–100
- `valid` — `Readable<boolean>` — true when no top-level upload errors
- `submit()` — programmatic form submit
- `cancel(ref?)` — cancel entry by ref string, or all when omitted
- `clear()` — reset file input
- `sync(config)` — merge updated config from server; call in `$effect`

---

### `useEventReply()`

Request-response pattern: push an event and await a reply.

```ts
import { useEventReply } from "live_svelte"
```

```svelte
<script>
  import { useEventReply } from "live_svelte"
  const { push } = useEventReply()

  async function save(data) {
    const result = await push("save", data)
    console.log("Server replied:", result)
  }
</script>
```

**Returns:**
- `push(event, payload)` — returns a `Promise` that resolves with the server reply

The LiveView must reply using `{:reply, payload, socket}` in `handle_event/3`:

```elixir
def handle_event("save", params, socket) do
  {:reply, %{status: "ok"}, socket}
end
```

---

### `Link` Component

Client-side navigation component. Svelte equivalent of Phoenix's `<.link>`.

```svelte
<script>
  import { Link } from "live_svelte"
</script>

<Link href="/other-page">Go to other page</Link>
<Link href="/other-page" replace={true}>Replace history</Link>
```

---

## Telemetry Events

| Event | Measurements | Metadata | Description |
|-------|-------------|----------|-------------|
| `[:live_svelte, :ssr, :start]` | `%{system_time: integer}` | `%{component: name}` | SSR render begins |
| `[:live_svelte, :ssr, :stop]` | `%{duration_microseconds: integer}` | `%{component: name}` | SSR render completes |
| `[:live_svelte, :ssr, :exception]` | `%{system_time: integer}` | `%{component: name, reason: term}` | SSR render fails |

---

## Configuration Keys

See [Configuration](configuration.md) for full details.

| Key | Default | Description |
|-----|---------|-------------|
| `config :live_svelte, :ssr` | `true` | Global SSR enable/disable |
| `config :live_svelte, :ssr_module` | `LiveSvelte.SSR.NodeJS` | SSR module |
| `config :live_svelte, :json_library` | `LiveSvelte.JSON` | JSON encoder |
| `config :live_svelte, :enable_props_diff` | `true` | Props diffing system |
| `config :live_svelte, :gettext_backend` | `nil` | Gettext for form errors |
| `config :live_svelte, :vite_host` | `"http://localhost:5173"` | Vite dev server URL |
