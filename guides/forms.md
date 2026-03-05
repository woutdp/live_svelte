# Forms and Validation

LiveSvelte provides `useLiveForm` for building reactive forms backed by Ecto changesets with server-side validation.

## Quick Example

**LiveView:**

```elixir
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view
  alias MyApp.Accounts

  def mount(_params, _session, socket) do
    form = to_form(Accounts.change_user(%Accounts.User{}))
    {:ok, assign(socket, form: form)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form = params |> Accounts.change_user() |> Map.put(:action, :validate) |> to_form()
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    case Accounts.create_user(params) do
      {:ok, _user} -> {:noreply, push_navigate(socket, to: "/")}
      {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <.svelte name="UserForm" props={%{form: @form}} socket={@socket} />
    """
  end
end
```

**Svelte Component:**

```svelte
<!-- assets/svelte/UserForm.svelte -->
<script>
  import { useLiveForm } from "live_svelte"

  let { form } = $props()

  const { field } = useLiveForm(() => form)
</script>

<form phx-submit="submit" phx-change="validate">
  <div>
    <label>Name</label>
    <input {...field("name")} />
    {#if field("name").error}
      <span class="error">{field("name").error}</span>
    {/if}
  </div>

  <div>
    <label>Email</label>
    <input type="email" {...field("email")} />
    {#if field("email").error}
      <span class="error">{field("email").error}</span>
    {/if}
  </div>

  <button type="submit">Save</button>
</form>
```

## The `useLiveForm` Composable

```ts
import { useLiveForm } from "live_svelte"

const { field, fieldArray } = useLiveForm(() => form, options?)
```

The first argument is a **getter function** (not the form value directly). This ensures `useLiveForm` always reads the latest reactive prop value.

### Options

```ts
type FormOptions = {
  changeEvent?: string      // Event name for validation (default: "validate")
  submitEvent?: string      // Event name for submission (default: "submit")
  debounceInMilliseconds?: number  // Debounce delay for change events (default: 300)
}
```

## The `field()` Function

`field(name)` returns an object you can spread onto an `<input>` element:

```svelte
<input {...field("email")} />
```

It returns:
- `name` — the HTML input name (matches changeset field)
- `value` — current field value from the changeset
- `error` — error message string (or `null`)
- `phx-debounce` — debounce attribute for change events

You can also access properties individually:

```svelte
<input
  name={field("email").name}
  value={field("email").value}
  class={field("email").error ? "border-red-500" : ""}
/>
{#if field("email").error}
  <p>{field("email").error}</p>
{/if}
```

## Nested Fields

Access nested fields with dot notation:

```svelte
<input {...field("address.street")} />
<input {...field("address.city")} />
```

## Dynamic Arrays with `fieldArray()`

For `embeds_many` or `has_many` with nested forms:

```svelte
<script>
  import { useLiveForm } from "live_svelte"

  let { form } = $props()
  const { field, fieldArray } = useLiveForm(() => form)

  const skills = fieldArray("skills")
</script>

{#each skills.fields as skillField, i}
  <div>
    <input {...field(`skills.${i}.name`)} />
    <button type="button" onclick={() => skills.remove(i)}>Remove</button>
  </div>
{/each}

<button type="button" onclick={() => skills.append({ name: "" })}>Add Skill</button>
```

`fieldArray(path)` returns:
- `fields` — reactive array of field descriptors
- `append(value)` — add an item to the end
- `prepend(value)` — add an item to the start
- `remove(index)` — remove an item by index

## Encoding Changesets as Props

To pass a changeset form as props, use `LiveSvelte.Encoder` for the changeset data. Phoenix's `to_form/1` produces a `Phoenix.HTML.Form` struct that LiveSvelte can encode automatically.

For custom structs used inside the form data, use `@derive`:

```elixir
defmodule MyApp.Address do
  @derive {LiveSvelte.Encoder, only: [:street, :city, :zip]}
  embedded_schema do
    field :street, :string
    field :city, :string
    field :zip, :string
  end
end
```

## TypeScript Types

```ts
import type { Form } from "live_svelte"

// Type your component props
let { form }: { form: Form<{ name: string; email: string }> } = $props()

const { field } = useLiveForm(() => form)
// field("name").value is typed as string
```

## Gettext Integration

If you have a Gettext backend configured, LiveSvelte translates error messages automatically:

```elixir
# config/config.exs
config :live_svelte, gettext_backend: MyAppWeb.Gettext
```

Error messages from changesets will use your Gettext translations.

## Full Form Example with Validation

```elixir
# LiveView
def handle_event("validate", %{"user" => params}, socket) do
  changeset =
    %User{}
    |> User.changeset(params)
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end
```

Setting `action: :validate` on the changeset causes Ecto to include validation errors, which LiveSvelte then passes back to the `field().error` values in the component.
