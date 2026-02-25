/**
 * Public API type definitions for LiveSvelte.
 * No `any` in public API; consumers get type safety and exported types.
 */

/**
 * Minimal LiveSocket interface for navigation composable.
 * Exposes only the methods needed for patch/navigate.
 */
export interface LiveSocket {
  pushHistoryPatch(event: Event, href: string, kind: "push" | "replace", target: Element | null): void;
  historyRedirect(event: Event, href: string, kind: "push" | "replace", flash: unknown, callback: (() => void) | null): void;
}

/** LiveView socket/channel push and event types (payloads from server are unknown) */
export type Live = {
  pushEvent(
    event: string,
    payload?: object,
    onReply?: (reply: unknown, ref: number) => void
  ): number;
  pushEventTo(
    phxTarget: unknown,
    event: string,
    payload?: object,
    onReply?: (reply: unknown, ref: number) => void
  ): number;

  handleEvent(event: string, callback: (payload: unknown) => void): () => void;
  removeHandleEvent(callbackRef: () => void): void;

  upload(name: string, files: FileList | File[]): void;
  uploadTo(phxTarget: unknown, name: string, files: FileList | File[]): void;

  /** The Phoenix LiveSocket instance — available on the hook `this` context. */
  liveSocket?: LiveSocket;
};

/** Component module input: default = modules, filenames = paths */
export interface ComponentModuleInput {
  default: Array<{ default: unknown }>;
  filenames: string[];
}

/** Result of getHooks: SvelteHook for LiveView hooks */
export interface SvelteHooksResult {
  SvelteHook: {
    mounted(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
    updated(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
    destroyed(this: { el: HTMLElement; _instance?: { state: Record<string, unknown> } }): void;
  };
}

/** Render function returned by getRender */
export type LiveSvelteRenderFn = (
  name: string,
  props: Record<string, unknown>,
  slots: Record<string, string>
) => {
  head: string;
  html: string;
  css: {
    code: string;
    map: string;
  };
};

export declare const getHooks: (components: ComponentModuleInput) => SvelteHooksResult;
export declare const getRender: (
  components: ComponentModuleInput
) => LiveSvelteRenderFn;

/**
 * Shape of the reactive connection-state object shared via Svelte context.
 * Keep in sync with the `LiveConnectionState` interface in composables.ts.
 */
export interface LiveConnectionState {
  connected: boolean;
}

/** Return type of useLiveSvelte() */
export interface UseLiveSvelteResult {
  readonly live: Live;
  pushEvent(event: string, payload?: object, onReply?: (reply: unknown, ref: number) => void): number;
  pushEventTo(phxTarget: unknown, event: string, payload?: object, onReply?: (reply: unknown, ref: number) => void): number;
}

/** Return type of useLiveConnection() */
export interface UseLiveConnectionResult {
  readonly connected: boolean;
}

/**
 * Access the Phoenix hook context from any Svelte component mounted by SvelteHook.
 * Returns pushEvent, pushEventTo, and the raw live ref.
 * @throws {Error} when called outside a LiveSvelte-mounted component tree
 */
export declare function useLiveSvelte(): UseLiveSvelteResult;

/**
 * Subscribe to a server-sent LiveView event with automatic cleanup on component destroy.
 * Calls live.handleEvent and registers the cleanup via onDestroy.
 * @throws {Error} when called outside a LiveSvelte-mounted component tree
 */
export declare function useLiveEvent(event: string, callback: (payload: unknown) => void): void;

/**
 * Observe the Phoenix WebSocket connection status.
 * Returns { connected } which is true when connected, false when disconnected.
 * Falls back to { connected: true } outside a LiveSvelte-mounted component.
 */
export declare function useLiveConnection(): UseLiveConnectionResult;

/** Return type of useLiveNavigation() */
export interface UseLiveNavigationResult {
  /** Patch the current LiveView — updates URL and triggers handle_params without a full reload. */
  patch(hrefOrQueryParams: string | Record<string, string>, opts?: { replace?: boolean }): void;
  /** Navigate to a new LiveView — mounts a new LV process without a full page reload. */
  navigate(href: string, opts?: { replace?: boolean }): void;
}

/**
 * Client-side LiveView navigation from a Svelte component.
 *
 * `patch()` updates the current LiveView (calls handle_params).
 * `navigate()` mounts a new LiveView process.
 * Both support `{ replace: true }` to use replaceState instead of pushState.
 *
 * @throws {Error} when called outside a LiveSvelte-mounted component tree
 * @throws {Error} when LiveSocket is not initialized
 */
export declare function useLiveNavigation(): UseLiveNavigationResult;

// ---------------------------------------------------------------------------
// useLiveForm types
// Keep in sync with useLiveForm.ts — that file is the source of truth.
// ---------------------------------------------------------------------------

import type { Readable } from "svelte/store";

/**
 * Recursive type for Ecto changeset error maps.
 * Each key maps to either an array of error strings or a nested error map.
 */
export type FormErrors<T extends object> = {
  [K in keyof T]?: string[] | Record<string, unknown>;
};

/**
 * Shape of a Phoenix.HTML.Form encoded by LiveSvelte.Encoder.
 * Produced by `to_form(changeset)` in the LiveView and passed as a prop.
 */
export interface Form<T extends object> {
  name: string;
  values: T;
  errors: FormErrors<T>;
  valid: boolean;
}

/** Options for `field()` to specify input type and checkbox value. */
export interface FieldOptions {
  type?: string;
  value?: unknown;
}

/** Options for `useLiveForm`. */
export interface FormOptions {
  changeEvent?: string | null;
  submitEvent?: string;
  debounceInMiliseconds?: number;
  prepareData?: (data: Record<string, unknown>) => Record<string, unknown>;
}

/** Attributes to spread onto an `<input>` element. */
export interface FieldAttrs {
  name: string;
  id: string;
  oninput: (e: Event) => void;
  onblur: () => void;
  "aria-invalid": boolean;
  "aria-describedby"?: string;
  value?: unknown;
  checked?: boolean;
  type?: string;
}

/** Reactive state snapshot for a single form field (the store's value). */
export interface FieldState<V> {
  value: V;
  errors: string[];
  errorMessage: string | undefined;
  isValid: boolean;
  isDirty: boolean;
  isTouched: boolean;
  attrs: FieldAttrs;
}

/**
 * A reactive field store. Subscribe via `$nameField` in Svelte templates.
 * Call `nameField.set(value)` to update the field value programmatically.
 */
export interface FormField<V> extends Readable<FieldState<V>> {
  set(value: V): void;
  update(updater: (currentValue: V) => V): void;
  field(subPath: string, options?: FieldOptions): FormField<any>;
  fieldArray(subPath: string): FormFieldArray<any>;
}

/**
 * A reactive array-field store with per-item field stores and
 * add/remove/move operations.
 */
export interface FormFieldArray<V> extends Readable<FieldState<V[]>> {
  set(value: V[]): void;
  fields: Readable<FormField<V>[]>;
  add(item?: Partial<V>): void;
  remove(index: number): void;
  move(from: number, to: number): void;
}

/** Return value of `useLiveForm`. */
export interface UseLiveFormReturn<T extends object> {
  isValid: Readable<boolean>;
  isDirty: Readable<boolean>;
  isTouched: Readable<boolean>;
  isValidating: Readable<boolean>;
  submitCount: Readable<number>;
  initialValues: Readonly<T>;
  field<V = unknown>(path: string, options?: FieldOptions): FormField<V>;
  fieldArray<V = unknown>(path: string): FormFieldArray<V>;
  submit(): Promise<any>;
  reset(): void;
  sync(newForm: Form<T>): void;
}

/**
 * Bind to an Ecto changeset form prop with reactive field instances.
 *
 * @example
 * ```svelte
 * <script lang="ts">
 *   import { useLiveForm } from "live_svelte"
 *   let { form: serverForm } = $props()
 *   const liveForm = useLiveForm(serverForm, { changeEvent: "validate", submitEvent: "submit" })
 *   $effect(() => { liveForm.sync(serverForm) })
 *   const nameField = liveForm.field("name")
 * </script>
 * <input {...$nameField.attrs} />
 * ```
 */
export declare function useLiveForm<T extends object>(
  form: Form<T>,
  options?: FormOptions
): UseLiveFormReturn<T>;

// ---------------------------------------------------------------------------
// useLiveUpload types
// Keep in sync with useLiveUpload.ts — that file is the source of truth.
// ---------------------------------------------------------------------------

/**
 * Shape of a single upload entry from Phoenix.LiveView.UploadEntry,
 * encoded by LiveSvelte.Encoder.
 */
export interface UploadEntry {
  /** Phoenix upload ref for this entry (e.g. "phx-ref-0"). */
  ref: string;
  /** Original filename from the client. */
  client_name: string;
  /** File size in bytes. */
  client_size: number;
  /** MIME type. */
  client_type: string;
  /** Upload progress 0–100. */
  progress: number;
  /** Whether the upload has completed. */
  done: boolean;
  /** Whether the entry passes accept/size validations. */
  valid: boolean;
  /** Whether Phoenix has acknowledged (preflighted) this entry. */
  preflighted: boolean;
  /** Entry-specific validation error messages. */
  errors: string[];
}

/**
 * Shape of a Phoenix.LiveView.UploadConfig encoded by LiveSvelte.Encoder.
 * Pass `@uploads.name` as a prop from the LiveView.
 */
export interface UploadConfig {
  /** Phoenix upload ref (e.g. "phx-abc123"). */
  ref: string;
  /** Upload name matching `allow_upload(:name, ...)` in the LiveView. */
  name: string;
  /** Accepted file types (e.g. ".jpg,.png") or false for any. */
  accept: string | false;
  /** Maximum number of concurrent uploads. */
  max_entries: number;
  /** When true, uploads begin as soon as files are selected. */
  auto_upload: boolean;
  /** Current upload entries. */
  entries: UploadEntry[];
  /** Top-level upload config errors (ref + error message pairs). */
  errors: { ref: string; error: string }[];
}

/** Options for `useLiveUpload`. */
export interface UploadOptions {
  /** Server event name for Phoenix phx-change (validation). Optional. */
  changeEvent?: string;
  /** Server event name for Phoenix phx-submit (required). */
  submitEvent: string;
}

/** Return value of `useLiveUpload`. */
export interface UseLiveUploadReturn {
  /** Reactive list of current upload entries from the server. */
  entries: Readable<UploadEntry[]>;
  /** Overall upload progress 0–100 averaged across all entries. */
  progress: Readable<number>;
  /** True when the upload config has no top-level errors. */
  valid: Readable<boolean>;
  /** The underlying hidden `<input type="file">` element store. */
  inputEl: Readable<HTMLInputElement | null>;
  /** Opens the native file-picker dialog. */
  showFilePicker(): void;
  /** Enqueue files from an array or DataTransfer (for drag-drop). */
  addFiles(files: File[] | DataTransfer): void;
  /** Dispatch a form submit event to trigger Phoenix upload (manual upload). */
  submit(): void;
  /** Cancel a specific entry by ref, or all entries when omitted. */
  cancel(ref?: string): void;
  /** Reset the hidden input value to clear the file queue. */
  clear(): void;
  /**
   * Merge an updated UploadConfig from the server into the composable.
   * Call from a Svelte `$effect(() => { upload.sync(props.uploads.avatar) })`.
   */
  sync(newConfig: UploadConfig): void;
}

/**
 * Bind to a Phoenix.LiveView.UploadConfig prop for reactive file upload management.
 *
 * @example
 * ```svelte
 * <script lang="ts">
 *   import { useLiveUpload } from "live_svelte"
 *   let { uploads } = $props()
 *   const upload = useLiveUpload(uploads.avatar, { changeEvent: "validate", submitEvent: "save" })
 *   $effect(() => { upload.sync(uploads.avatar) })
 * </script>
 * <button onclick={() => upload.showFilePicker()}>Select Files</button>
 * {#each $upload.entries as entry}{entry.client_name}{/each}
 * ```
 */
export declare function useLiveUpload(
  uploadConfig: UploadConfig,
  options: UploadOptions
): UseLiveUploadReturn;

// ---------------------------------------------------------------------------
// useEventReply types
// Keep in sync with useEventReply.ts — that file is the source of truth.
// ---------------------------------------------------------------------------

/** Options for `useEventReply`. */
export interface UseEventReplyOptions<T> {
  /** Initial value for `data` store before first reply. Defaults to `null`. */
  defaultValue?: T;
  /**
   * Transform the reply before storing it in `data`.
   * Receives the server reply and current store value; return value is stored.
   */
  updateData?: (reply: T, currentData: T | null) => T;
  /** Reject the promise if the LiveView has not replied within this many milliseconds. */
  timeout?: number;
}

/** Return value of `useEventReply`. */
export interface UseEventReplyReturn<T, P extends object | void = object> {
  /** Reactive store of the last reply data (`null` until first successful reply). */
  data: Readable<T | null>;
  /** `true` while the event is in-flight, `false` otherwise. */
  isLoading: Readable<boolean>;
  /**
   * Push the named event to Phoenix with optional params.
   * Returns a promise that resolves with the reply payload from `{:reply, map, socket}`.
   * Rejects if already executing, if no LiveSvelte context, or if timeout expires.
   */
  execute(params?: P): Promise<T>;
  /**
   * Cancel the in-flight execution.
   * Rejects the pending promise and resets `isLoading` to `false`.
   */
  cancel(): void;
}

/**
 * Bind a LiveView event to a reactive request-response composable.
 *
 * @example
 * ```svelte
 * <script lang="ts">
 *   import { useEventReply } from "live_svelte"
 *   const { data, isLoading, execute, cancel } = useEventReply<{ result: number }>("compute")
 * </script>
 * <button onclick={() => execute({ value: 21 })}>{$isLoading ? "Loading..." : "Go"}</button>
 * {#if $data}<p>{$data.result}</p>{/if}
 * ```
 */
export declare function useEventReply<T = unknown, P extends object | void = object>(
  eventName: string,
  options?: UseEventReplyOptions<T>
): UseEventReplyReturn<T, P>;

