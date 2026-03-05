# File Uploads

LiveSvelte provides `useLiveUpload` for integrating Phoenix LiveView's file upload system with Svelte components.

## Quick Example

**LiveView:**

```elixir
defmodule MyAppWeb.UploadLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.jpg .png), max_entries: 1)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest = Path.join("priv/static/uploads", Path.basename(path))
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    {:noreply,
     socket
     |> update(:uploaded_files, &(&1 ++ uploaded_files))
     |> put_flash(:info, "Uploaded successfully!")}
  end

  def render(assigns) do
    ~H"""
    <.svelte
      name="AvatarUpload"
      props={%{uploads: @uploads}}
      socket={@socket}
    />
    """
  end
end
```

**Svelte Component:**

```svelte
<!-- assets/svelte/AvatarUpload.svelte -->
<script>
  import { useLiveUpload } from "live_svelte"

  let { uploads } = $props()

  const {
    showFilePicker,
    entries,
    submit,
    cancel,
    clear,
    sync
  } = useLiveUpload(uploads.avatar, { changeEvent: "validate", submitEvent: "submit" })

  // Keep the composable in sync when the server pushes updated upload config
  $effect(() => sync(uploads.avatar))
</script>

<div
  role="button"
  tabindex="0"
  onclick={showFilePicker}
  onkeydown={(e) => e.key === "Enter" && showFilePicker()}
>
  Click to select a file (or drag and drop)
</div>

{#each $entries as entry (entry.ref)}
  <div>
    <p>{entry.client_name}</p>

    <!-- Progress bar -->
    <progress value={entry.progress} max="100">{entry.progress}%</progress>

    <!-- Validation errors -->
    {#each entry.errors as error}
      <p class="error">{error}</p>
    {/each}

    <button type="button" onclick={() => cancel(entry.ref)}>Remove</button>
  </div>
{/each}

<button onclick={submit} disabled={$entries.length === 0}>Upload</button>
```

## The `useLiveUpload` Composable

```ts
import { useLiveUpload } from "live_svelte"

const { showFilePicker, entries, submit, cancel, clear, sync } = useLiveUpload(
  uploads.avatar,
  { changeEvent: "validate", submitEvent: "submit" }
)

// Sync updated config from server on every render
$effect(() => sync(uploads.avatar))
```

The first argument is the **upload config object** for a specific upload field (e.g., `uploads.avatar`). Pass it directly — not as a getter function.

Call `sync(uploads.avatar)` in a `$effect` to keep the composable up-to-date whenever the server sends an updated config.

> `useLiveUpload` creates a hidden `<form>` and `<input type="file">` internally and appends them to the LiveView element. You do not need to add a form in your Svelte template.

### Options

```ts
interface UploadOptions {
  changeEvent?: string  // Server event for phx-change (validation). Optional.
  submitEvent: string   // Server event for phx-submit. REQUIRED.
}
```

## Return Values

| Value | Type | Description |
|-------|------|-------------|
| `showFilePicker()` | `() => void` | Opens the native file picker dialog |
| `addFiles(files)` | `(files: File[] \| DataTransfer) => void` | Enqueue files programmatically (for drag-drop) |
| `entries` | `Readable<UploadEntry[]>` | Reactive store of current upload entries. Use `$entries` in templates. |
| `progress` | `Readable<number>` | Overall upload progress 0–100 averaged across all entries |
| `valid` | `Readable<boolean>` | `true` when the upload config has no top-level errors |
| `submit()` | `() => void` | Dispatch a form submit event to trigger Phoenix upload |
| `cancel(ref?)` | `(ref?: string) => void` | Cancel entry by ref string, or all entries when called with no arg |
| `clear()` | `() => void` | Reset the hidden input to clear the file queue |
| `sync(config)` | `(config: UploadConfig) => void` | Merge updated config from server. Call in `$effect`. |

## Upload Entry Fields

Each entry in `entries` has:

| Field | Type | Description |
|-------|------|-------------|
| `ref` | `string` | Unique entry identifier |
| `client_name` | `string` | Original filename |
| `client_size` | `number` | File size in bytes |
| `client_type` | `string` | MIME type |
| `progress` | `number` | Upload progress (0–100) |
| `errors` | `string[]` | Validation error messages |
| `valid` | `boolean` | Whether entry passes validation |
| `done` | `boolean` | Whether upload is complete |
| `preflighted` | `boolean` | Whether Phoenix has acknowledged (preflighted) this entry |

## Drag and Drop

```svelte
<script>
  import { useLiveUpload } from "live_svelte"

  let { uploads } = $props()
  const { entries, cancel, sync } = useLiveUpload(uploads.avatar, { submitEvent: "submit" })
  $effect(() => sync(uploads.avatar))
  let dragOver = $state(false)
</script>

<div
  class={dragOver ? "drag-over" : ""}
  ondragover={(e) => { e.preventDefault(); dragOver = true }}
  ondragleave={() => { dragOver = false }}
  ondrop={(e) => {
    e.preventDefault()
    dragOver = false
    // Phoenix LiveView handles the drop via phx-drop-target
  }}
  phx-drop-target={uploads.avatar?.ref}
>
  Drop files here
</div>
```

## Multiple Files

Configure `max_entries` on the LiveView side:

```elixir
allow_upload(:photos, accept: ~w(.jpg .png .gif), max_entries: 5)
```

The `entries` array in the component will reflect all selected files.

## Validation

File validation is configured with `allow_upload/3` options:

```elixir
allow_upload(:avatar,
  accept: ~w(.jpg .png .webp),
  max_entries: 1,
  max_file_size: 10_000_000  # 10 MB
)
```

Validation errors appear in `entry.errors` as human-readable strings.

## Progress Tracking

Upload progress is automatically tracked per entry via `entry.progress` (0–100):

```svelte
{#each $entries as entry (entry.ref)}
  <div class="upload-item">
    <span>{entry.client_name}</span>
    <div class="progress-bar" style="width: {entry.progress}%"></div>
    {#if entry.done}
      <span>✓ Complete</span>
    {/if}
  </div>
{/each}
```
