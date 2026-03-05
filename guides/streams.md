# Phoenix Streams

LiveSvelte has native support for [Phoenix Streams](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4), enabling efficient DOM list management without holding full lists in memory on the server.

## Basic Streams

**LiveView:**

```elixir
defmodule MyAppWeb.ItemsLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, stream(socket, :items, MyApp.list_items())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    item = MyApp.get_item!(id)
    MyApp.delete_item!(item)
    {:noreply, stream_delete(socket, :items, item)}
  end

  def render(assigns) do
    ~H"""
    <.svelte name="ItemList" props={%{items: @streams.items}} socket={@socket} />
    """
  end
end
```

**Svelte Component:**

```svelte
<!-- assets/svelte/ItemList.svelte -->
<script>
  let { items } = $props()
</script>

{#each items as item (item.__dom_id)}
  <div id={item.__dom_id}>
    <p>{item.name}</p>
  </div>
{/each}
```

> #### Use `__dom_id` as the key {: .info}
>
> Always use `item.__dom_id` as the `{#each}` key. LiveSvelte uses this to track item identity for efficient updates.

## Stream Operations

All Phoenix stream operations work automatically:

```elixir
# Insert at the end (default)
socket |> stream_insert(socket, :items, new_item)

# Insert at the beginning
socket |> stream_insert(socket, :items, new_item, at: 0)

# Delete by item (must have :id field)
socket |> stream_delete(socket, :items, item)

# Reset the entire stream
socket |> stream(socket, :items, new_items, reset: true)
```

## Efficient Stream Patches

LiveSvelte sends stream changes as compact JSON Patch operations via `data-streams-diff`, rather than re-sending the full list on every change. This makes stream updates extremely efficient — inserting a single item sends a single operation regardless of list size.

The patch operations used:

| Operation | Description |
|-----------|-------------|
| `upsert` | Insert or update an item at a specific position |
| `remove` | Delete an item by `__dom_id` |
| `replace` | Reset the entire list |
| `limit` | Trim the list to the given max size |

These are applied client-side by the `SvelteHook` before updating the Svelte component's `items` prop.

## Accessing Stream Data in Components

Streams are passed as arrays to Svelte components. Each item has all its original fields plus `__dom_id`:

```svelte
<script>
  let { messages } = $props()
</script>

<ul>
  {#each messages as message (message.__dom_id)}
    <li id={message.__dom_id}>
      <strong>{message.user}</strong>: {message.text}
    </li>
  {/each}
</ul>
```

## Multiple Streams

Pass multiple streams to a single component:

```elixir
def mount(_, _, socket) do
  {:ok,
   socket
   |> stream(:messages, [])
   |> stream(:users, [])}
end

def render(assigns) do
  ~H"""
  <.svelte
    name="Chat"
    props={%{messages: @streams.messages, users: @streams.users}}
    socket={@socket}
  />
  """
end
```

```svelte
<script>
  let { messages, users } = $props()
</script>

<!-- Both streams update independently and efficiently -->
```

## Encoding Stream Items

Stream items go through `LiveSvelte.Encoder` before being sent to the client. For custom structs, add `@derive`:

```elixir
defmodule MyApp.Message do
  @derive {LiveSvelte.Encoder, only: [:id, :user, :text, :inserted_at]}
  defstruct [:id, :user, :text, :inserted_at]
end
```

The `@derive` restriction is enforced — fields not in `only:` are excluded even after `__dom_id` is added.

## ID-Based Diffing

For arrays where items have an `:id` field, LiveSvelte uses ID-based list diffing (Tier 3 of the props diffing system). This means:

- Inserting at position 0 sends a single `upsert` op, not N `replace` ops
- Reordering sends minimal operations
- List updates stay efficient regardless of list size

Items must have an `:id` field for ID-based diffing to activate. The `__dom_id` set by Phoenix Streams already guarantees this.
