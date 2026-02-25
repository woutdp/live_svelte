/**
 * LiveSvelte composables — ergonomic access to the Phoenix hook context
 * from any Svelte component mounted by SvelteHook, without prop drilling.
 *
 * Context architecture:
 *   The SvelteHook passes live ref and connection state via Svelte's context
 *   system (mount/hydrate `context` option). Composables read from that context.
 *
 * Backward compatibility:
 *   The `live` prop is still passed to Svelte components for existing code.
 *   Composables are an additive ergonomics improvement.
 */

import { getContext, onDestroy } from "svelte"
import type { Live, LiveSocket, UseLiveNavigationResult } from "./types"

/** Context key for the Phoenix hook reference (`this` inside SvelteHook). */
export const LIVE_SYMBOL = Symbol("__live_svelte__")

/**
 * Context key for the reactive connection state object.
 * The SvelteHook sets this to `{ connected: boolean }` and updates it
 * via its `disconnected()` / `reconnected()` lifecycle callbacks.
 */
export const CONNECTION_SYMBOL = Symbol("__live_svelte_connection__")

/** Shape of the connection state object shared via context. */
export interface LiveConnectionState {
  connected: boolean
}

/** Return type of useLiveSvelte(). */
export interface UseLiveSvelteResult {
  /** The raw Phoenix hook context. Prefer pushEvent/pushEventTo for type safety. */
  readonly live: Live
  pushEvent: Live["pushEvent"]
  pushEventTo: Live["pushEventTo"]
}

/** Return type of useLiveConnection(). */
export interface UseLiveConnectionResult {
  /** `true` when the Phoenix WebSocket is connected, `false` when disconnected. */
  readonly connected: boolean
}

/**
 * Access the Phoenix hook context from any Svelte component mounted by SvelteHook.
 *
 * @throws {Error} When called outside a LiveSvelte-mounted component tree.
 *
 * @example
 * ```svelte
 * <script>
 *   import { useLiveSvelte } from "live_svelte"
 *   const { pushEvent } = useLiveSvelte()
 *   function save() { pushEvent("save", { value }) }
 * </script>
 * ```
 */
export function useLiveSvelte(): UseLiveSvelteResult {
  const live = getContext<Live>(LIVE_SYMBOL)
  if (!live) {
    if (typeof window === "undefined") {
      const noop = () => {}
      return { live: null as unknown as Live, pushEvent: noop as Live["pushEvent"], pushEventTo: noop as Live["pushEventTo"] }
    }
    throw new Error("useLiveSvelte() must be called inside a LiveSvelte-mounted component")
  }
  return {
    get live() {
      return live
    },
    pushEvent: (...args: Parameters<Live["pushEvent"]>) => live.pushEvent(...args),
    pushEventTo: (...args: Parameters<Live["pushEventTo"]>) => live.pushEventTo(...args),
  }
}

/**
 * Subscribe to a server-sent LiveView event with automatic cleanup on component destroy.
 *
 * Calls `live.handleEvent(event, callback)` and registers the returned cleanup
 * function with `onDestroy` — no manual `removeHandleEvent` needed.
 *
 * @note Calling `useLiveEvent` multiple times with the same event name registers
 * multiple independent subscriptions — all callbacks fire on each event.
 * This is intentional; deduplicate in the caller if needed.
 *
 * @throws {Error} When called outside a LiveSvelte-mounted component tree.
 *
 * @example
 * ```svelte
 * <script>
 *   import { useLiveEvent } from "live_svelte"
 *   useLiveEvent("item_added", (payload) => { console.log(payload) })
 * </script>
 * ```
 */
export function useLiveEvent(event: string, callback: (payload: unknown) => void): void {
  const live = getContext<Live>(LIVE_SYMBOL)
  if (!live) {
    if (typeof window === "undefined") return
    throw new Error("useLiveEvent() must be called inside a LiveSvelte-mounted component")
  }
  const cleanup = live.handleEvent(event, callback)
  onDestroy(cleanup)
}

/**
 * Observe the Phoenix WebSocket connection status as a reactive value.
 *
 * Connection state is managed by the SvelteHook via `disconnected()` /
 * `reconnected()` lifecycle callbacks. Returns `{ connected: true }` when
 * called outside a LiveSvelte context (e.g. SSR, tests).
 *
 * @example
 * ```svelte
 * <script>
 *   import { useLiveConnection } from "live_svelte"
 *   const conn = useLiveConnection()
 * </script>
 * {#if !conn.connected}
 *   <p>Reconnecting…</p>
 * {/if}
 * ```
 */
export function useLiveConnection(): UseLiveConnectionResult {
  const state = getContext<LiveConnectionState>(CONNECTION_SYMBOL)
  if (!state) {
    // Outside LiveSvelte context — assume connected (SSR, unit testing)
    return { connected: true }
  }
  return {
    get connected() {
      return state.connected
    },
  }
}

/**
 * Client-side LiveView navigation from a Svelte component.
 *
 * Uses the `liveSocket` instance on the Phoenix hook context to perform
 * navigation without full page reloads. Mirrors LiveVue's `useLiveNavigation`.
 *
 * - `patch()` patches the current LiveView (triggers `handle_params/3`).
 * - `navigate()` mounts a new LiveView process (within the same live_session).
 * - Both accept `{ replace: true }` to use `history.replaceState`.
 *
 * @throws {Error} When called outside a LiveSvelte-mounted component tree.
 * @throws {Error} When `live.liveSocket` is not initialized.
 *
 * @example
 * ```svelte
 * <script>
 *   import { useLiveNavigation } from "live_svelte"
 *   const { patch, navigate } = useLiveNavigation()
 * </script>
 * <button onclick={() => patch("?page=2")}>Next page</button>
 * <button onclick={() => navigate("/other-view")}>Go elsewhere</button>
 * ```
 */
export function useLiveNavigation(): UseLiveNavigationResult {
  const live = getContext<Live>(LIVE_SYMBOL)
  if (!live) {
    if (typeof window === "undefined") return { patch: () => {}, navigate: () => {} }
    throw new Error("useLiveNavigation() must be called inside a LiveSvelte-mounted component")
  }
  const liveSocket = live.liveSocket as LiveSocket | undefined
  if (!liveSocket) throw new Error("LiveSocket not initialized")

  const patch = (
    hrefOrQueryParams: string | Record<string, string>,
    opts: { replace?: boolean } = {}
  ): void => {
    let href =
      typeof hrefOrQueryParams === "string"
        ? hrefOrQueryParams
        : globalThis.location.pathname
    if (typeof hrefOrQueryParams === "object") {
      const queryParams = new URLSearchParams(hrefOrQueryParams)
      href = `${href}?${queryParams.toString()}`
    }
    liveSocket.pushHistoryPatch(new Event("click"), href, opts.replace ? "replace" : "push", null)
  }

  const navigate = (href: string, opts: { replace?: boolean } = {}): void => {
    liveSocket.historyRedirect(new Event("click"), href, opts.replace ? "replace" : "push", null, null)
  }

  return { patch, navigate }
}
