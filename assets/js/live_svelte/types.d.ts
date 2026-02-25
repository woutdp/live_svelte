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

