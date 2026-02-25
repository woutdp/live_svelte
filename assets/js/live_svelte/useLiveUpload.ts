/**
 * useLiveUpload — Svelte composable for Phoenix LiveView file uploads.
 *
 * Binds to a Phoenix.LiveView.UploadConfig encoded by LiveSvelte.Encoder,
 * managing a hidden <form>/<input type=file> with the required Phoenix upload
 * attributes, and exposing reactive stores for entries, progress, and validity.
 *
 * Usage:
 * ```svelte
 * <script lang="ts">
 *   import { useLiveUpload } from "live_svelte"
 *   import type { UploadConfig } from "live_svelte"
 *
 *   interface Props { uploads: { avatar: UploadConfig }; uploaded_files: { name: string }[] }
 *   let { uploads, uploaded_files }: Props = $props()
 *
 *   const upload = useLiveUpload(uploads.avatar, { changeEvent: "validate", submitEvent: "save" })
 *   $effect(() => { upload.sync(uploads.avatar) })
 * </script>
 *
 * <button onclick={() => upload.showFilePicker()}>Select Files</button>
 * {#each $upload.entries as entry (entry.ref)}
 *   <div>{entry.client_name} — {entry.progress}%</div>
 * {/each}
 * ```
 */

import { writable, derived, get, type Readable, type Writable } from "svelte/store"
import { onMount } from "svelte"
import { useLiveSvelte } from "./composables"

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/**
 * Shape of a single upload entry from Phoenix.LiveView.UploadEntry,
 * encoded by LiveSvelte.Encoder.
 */
export interface UploadEntry {
  /** Phoenix upload ref for this entry (e.g. "phx-ref-0"). */
  ref: string
  /** Original filename from the client. */
  client_name: string
  /** File size in bytes. */
  client_size: number
  /** MIME type. */
  client_type: string
  /** Upload progress 0–100. */
  progress: number
  /** Whether the upload has completed. */
  done: boolean
  /** Whether the entry passes accept/size validations. */
  valid: boolean
  /** Whether Phoenix has acknowledged (preflighted) this entry. */
  preflighted: boolean
  /** Entry-specific validation error messages. */
  errors: string[]
}

/**
 * Shape of a Phoenix.LiveView.UploadConfig encoded by LiveSvelte.Encoder.
 * Pass `@uploads.name` as a prop from the LiveView.
 */
export interface UploadConfig {
  /** Phoenix upload ref (e.g. "phx-abc123"). */
  ref: string
  /** Upload name matching `allow_upload(:name, ...)` in the LiveView. */
  name: string
  /** Accepted file types (e.g. ".jpg,.png") or false for any. */
  accept: string | false
  /** Maximum number of concurrent uploads. */
  max_entries: number
  /** When true, uploads begin as soon as files are selected. */
  auto_upload: boolean
  /** Current upload entries. */
  entries: UploadEntry[]
  /** Top-level upload config errors. */
  errors: { ref: string; error: string }[]
}

/** Options for `useLiveUpload`. */
export interface UploadOptions {
  /** Server event name for Phoenix phx-change (validation). */
  changeEvent?: string
  /** Server event name for Phoenix phx-submit (required). */
  submitEvent: string
}

/** Return value of `useLiveUpload`. */
export interface UseLiveUploadReturn {
  /** Reactive list of current upload entries from the server. */
  entries: Readable<UploadEntry[]>
  /** Overall upload progress 0–100 averaged across all entries. */
  progress: Readable<number>
  /** True when the upload config has no top-level errors. */
  valid: Readable<boolean>
  /** The underlying hidden `<input type="file">` element store. */
  inputEl: Readable<HTMLInputElement | null>
  /** Opens the native file-picker dialog. */
  showFilePicker(): void
  /** Enqueue files from an array or DataTransfer (for drag-drop). */
  addFiles(files: File[] | DataTransfer): void
  /** Dispatch a form submit event to trigger Phoenix upload (manual upload). */
  submit(): void
  /** Cancel a specific entry by ref, or all entries when omitted. */
  cancel(ref?: string): void
  /** Reset the hidden input value to clear the file queue. */
  clear(): void
  /**
   * Merge an updated UploadConfig from the server into the composable.
   * Call from a Svelte `$effect(() => { upload.sync(props.uploads.avatar) })`.
   */
  sync(newConfig: UploadConfig): void
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export function useLiveUpload(
  uploadConfig: UploadConfig,
  options: UploadOptions
): UseLiveUploadReturn {
  // Graceful degradation: works without LiveSvelte context (SSR, tests without mock).
  let liveCtx: ReturnType<typeof useLiveSvelte> | null = null
  try {
    liveCtx = useLiveSvelte()
  } catch {
    // SSR or test without LiveSvelte context — pushEvent unavailable.
  }

  // Core reactive store for the upload config.
  const configStore: Writable<UploadConfig> = writable(uploadConfig)

  // Reactive hidden input element store.
  const inputElStore: Writable<HTMLInputElement | null> = writable(null)

  // Derived stores.
  const entries: Readable<UploadEntry[]> = derived(configStore, ($config) => $config.entries ?? [])

  const progress: Readable<number> = derived(entries, ($entries) => {
    if ($entries.length === 0) return 0
    const total = $entries.reduce((sum, entry) => sum + (entry.progress ?? 0), 0)
    return Math.round(total / $entries.length)
  })

  const valid: Readable<boolean> = derived(
    configStore,
    ($config) => ($config.errors ?? []).length === 0
  )

  // DOM setup: create the hidden form+input with Phoenix upload attributes.
  onMount(() => {
    const config = get(configStore)

    // Outer form carries phx-change / phx-submit so Phoenix hooks it.
    const form = document.createElement("form")
    if (options.changeEvent) form.setAttribute("phx-change", options.changeEvent)
    form.setAttribute("phx-submit", options.submitEvent)
    form.style.display = "none"

    const input = document.createElement("input")
    input.type = "file"
    input.id = config.ref
    input.name = config.name

    // REQUIRED Phoenix LiveFileUpload hook attributes.
    input.setAttribute("data-phx-hook", "Phoenix.LiveFileUpload")
    input.setAttribute("data-phx-update", "ignore")
    input.setAttribute("data-phx-upload-ref", config.ref)

    // Optional attributes derived from the upload config.
    if (config.accept && typeof config.accept === "string") {
      input.accept = config.accept
    }
    if (config.auto_upload) {
      input.setAttribute("data-phx-auto-upload", "true")
    }
    if (config.max_entries > 1) {
      input.multiple = true
    }

    form.appendChild(input)

    // Append to the LiveView element so Phoenix can find the input.
    const liveEl = (liveCtx?.live as { el?: Element } | null)?.el
    if (liveEl) {
      liveEl.appendChild(form)
    }

    inputElStore.set(input)

    // Subscribe to configStore to keep Phoenix ref attributes up-to-date.
    const unsub = configStore.subscribe(($config) => {
      const joinRefs = (es: UploadEntry[]) => es.map((e) => e.ref).join(",")
      input.setAttribute("data-phx-active-refs", joinRefs($config.entries))
      input.setAttribute("data-phx-done-refs", joinRefs($config.entries.filter((e) => e.done)))
      input.setAttribute(
        "data-phx-preflighted-refs",
        joinRefs($config.entries.filter((e) => e.preflighted))
      )
    })

    // Cleanup: unsubscribe, remove the form, and clear the store.
    return () => {
      unsub()
      form.remove()
      inputElStore.set(null)
    }
  })

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  function showFilePicker(): void {
    const input = get(inputElStore)
    if (input) input.click()
  }

  function addFiles(files: File[] | DataTransfer): void {
    const input = get(inputElStore)
    if (!input) return

    const DataTransferClass =
      typeof DataTransfer !== "undefined" ? DataTransfer : null
    let filesSet = false
    if (DataTransferClass && files instanceof DataTransferClass) {
      input.files = (files as DataTransfer).files
      filesSet = true
    } else if (DataTransferClass) {
      const dt = new DataTransferClass()
      ;(files as File[]).forEach((f) => dt.items.add(f))
      input.files = dt.files
      filesSet = true
    }

    // Dispatch asynchronously so Phoenix has initialised the upload system.
    // Only dispatch if files were actually set — avoids spurious events in
    // environments where DataTransfer is unavailable (e.g. SSR/Node.js).
    if (filesSet) {
      setTimeout(() => {
        const current = get(inputElStore)
        if (current) current.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }))
      }, 0)
    }
  }

  function submit(): void {
    const input = get(inputElStore)
    if (input?.form) {
      input.form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }))
    }
  }

  function cancel(ref?: string): void {
    if (!liveCtx) return
    if (ref !== undefined) {
      liveCtx.pushEvent("cancel-upload", { ref })
    } else {
      get(entries).forEach((entry) => {
        liveCtx!.pushEvent("cancel-upload", { ref: entry.ref })
      })
    }
  }

  function clear(): void {
    const input = get(inputElStore)
    if (input) input.value = ""
  }

  function sync(newConfig: UploadConfig): void {
    configStore.set(newConfig)
  }

  return {
    entries,
    progress,
    valid,
    inputEl: { subscribe: inputElStore.subscribe },
    showFilePicker,
    addFiles,
    submit,
    cancel,
    clear,
    sync,
  }
}
