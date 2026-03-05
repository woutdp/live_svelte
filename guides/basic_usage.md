# Basic Usage

This guide covers the fundamentals of using LiveSvelte: the `<.svelte>` component, props, events, and the `~V` sigil.

## Your First Component

### 1. Create a Svelte component

Place Svelte files in `assets/svelte/`. LiveSvelte discovers all `*.svelte` files in that directory at compile time.

```svelte
<!-- assets/svelte/Counter.svelte -->
<script>
  let { count, live } = $props()

  function increment() {
    live.pushEvent("increment", {})
  }
</script>

<div>
  <p>Count: {count}</p>
  <button onclick={increment}>Increment</button>
</div>
```

### 2. Use it in a LiveView

```elixir
# lib/my_app_web/live/counter_live.ex
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <.svelte name="Counter" props={%{count: @count}} socket={@socket} />
    """
  end
end
```

That's it. When the user clicks the button, `pushEvent("increment", {})` sends the event to `handle_event/3`, the count is incremented, and Svelte re-renders automatically.

## Props

Pass any JSON-serializable map as `props`:

```heex
<.svelte name="UserCard" props={%{name: @user.name, role: @user.role}} socket={@socket} />
```

In the component, receive with `$props()`:

```svelte
<script>
  let { name, role } = $props()
</script>

<div>
  <h2>{name}</h2>
  <span>{role}</span>
</div>
```

### Struct Props

Structs must implement the `LiveSvelte.Encoder` protocol before being passed as props. Use `@derive` for the default implementation:

```elixir
defmodule MyApp.User do
  @derive {LiveSvelte.Encoder, only: [:id, :name, :email]}
  defstruct [:id, :name, :email, :password_hash]
end
```

The `only:` list controls which fields are exposed. Never derive without `only:` for structs with sensitive fields.

## The `live` Prop

LiveSvelte automatically passes a `live` prop to every mounted component. Use it to communicate with the server:

```svelte
<script>
  let { live } = $props()

  // Push event to server (fire-and-forget)
  function save(data) {
    live.pushEvent("save", data)
  }

  // Push event and receive reply
  function saveWithReply(data) {
    live.pushEvent("save", data, (reply) => {
      console.log("Server replied:", reply)
    })
  }

  // Subscribe to server-sent events
  live.handleEvent("flash", ({ message }) => {
    alert(message)
  })
</script>
```

## Composable Alternative to `live` Prop

Instead of using the `live` prop, you can use composables which work from any component in the tree — no prop drilling:

```svelte
<script>
  import { useLiveSvelte, useLiveEvent } from "live_svelte"

  const { pushEvent } = useLiveSvelte()

  useLiveEvent("flash", ({ message }) => {
    alert(message)
  })

  function save(data) {
    pushEvent("save", data)
  }
</script>
```

See the [API Reference](api_reference.md) for all composables.

## Component Shorthand with `LiveSvelte.Components`

Add `use LiveSvelte.Components` to your LiveView (or web module) for shorthand component functions:

```elixir
# In web module html_helpers (added by Igniter installer):
import LiveSvelte
use LiveSvelte.Components
```

Then instead of `<.svelte name="Counter" ...>`, use:

```heex
<.Counter count={@count} socket={@socket} />
```

The function names are generated from your `.svelte` filenames. `Counter.svelte` → `<.Counter>`, `UserCard.svelte` → `<.UserCard>`.

> #### `socket` is required for SSR {: .info}
>
> Always pass `socket={@socket}` when SSR is enabled. It's used to detect the initial dead render vs. connected live render. You can omit it only when `ssr={false}`.

## Inline Templates with the `~V` Sigil

For small, one-off components, write Svelte templates inline using the `~V` sigil:

```elixir
def render(assigns) do
  ~V"""
  <script>
    let { count } = $props()
  </script>
  <p>Count is {count}</p>
  """
end
```

The sigil writes the template to `assets/svelte/_build/` at compile time and mounts it like any other component. All LiveView assigns are automatically available as props.

> #### Svelte 5 Syntax Required {: .warning}
>
> Always use Svelte 5 runes syntax. Do NOT use Svelte 4 patterns:
>
> | ❌ Svelte 4 | ✅ Svelte 5 |
> |-------------|-------------|
> | `export let count` | `let { count } = $props()` |
> | `let x = 0` (reactive) | `let x = $state(0)` |
> | `$: doubled = x * 2` | `let doubled = $derived(x * 2)` |
> | `<script context="module">` | module-level code in `.js` files |

## Local State

Local component state uses `$state()`:

```svelte
<script>
  let { items } = $props()

  let filter = $state("")
  let filtered = $derived(items.filter(i => i.name.includes(filter)))
</script>

<input bind:value={filter} placeholder="Filter..." />

{#each filtered as item}
  <li>{item.name}</li>
{/each}
```

## Component Discovery

LiveSvelte scans `assets/svelte/**/*.svelte` at compile time. Component names in `<.svelte name="...">` are relative paths without the `.svelte` extension:

```
assets/svelte/Counter.svelte        → name="Counter"
assets/svelte/forms/UserForm.svelte → name="forms/UserForm"
```

## phx-update="ignore"

LiveSvelte automatically sets `phx-update="ignore"` on the component wrapper div, which prevents LiveView from patching Svelte's DOM after mount. All updates flow through the hook. This is required for correct operation — do not override it.
