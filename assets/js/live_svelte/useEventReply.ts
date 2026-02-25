/**
 * useEventReply — Svelte composable for Phoenix LiveView request-response events.
 *
 * Binds a named event to pushEvent, returning reactive `data` and `isLoading` stores
 * plus a promise-based `execute()` that resolves with the server's {:reply, map, socket}.
 *
 * Usage:
 * ```svelte
 * <script lang="ts">
 *   import { useEventReply } from "live_svelte"
 *
 *   const { data, isLoading, execute, cancel } = useEventReply<{ result: number }>("compute")
 * </script>
 *
 * <button onclick={() => execute({ value: 21 })}>
 *   {$isLoading ? "Loading..." : "Compute"}
 * </button>
 * {#if $data}
 *   <p>Result: {$data.result}</p>
 * {/if}
 * ```
 */

import { writable, get, type Readable, type Writable } from "svelte/store"
import { onDestroy } from "svelte"
import { useLiveSvelte } from "./composables"

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/** Options for `useEventReply`. */
export interface UseEventReplyOptions<T> {
  /** Initial value for `data` store before first reply. Defaults to `null`. */
  defaultValue?: T
  /**
   * Transform the reply before storing it in `data`.
   * Receives the server reply and current store value; return value is stored.
   */
  updateData?: (reply: T, currentData: T | null) => T
  /** Reject the promise if the LiveView has not replied within this many milliseconds. */
  timeout?: number
}

/** Return value of `useEventReply`. */
export interface UseEventReplyReturn<T, P extends object | void = object> {
  /** Reactive store of the last reply data (`null` until first successful reply). */
  data: Readable<T | null>
  /** `true` while the event is in-flight, `false` otherwise. */
  isLoading: Readable<boolean>
  /**
   * Push the named event to Phoenix with optional params.
   * Returns a promise that resolves with the reply payload from `{:reply, map, socket}`.
   * Rejects if already executing, if no LiveSvelte context, or if timeout expires.
   */
  execute(params?: P): Promise<T>
  /**
   * Cancel the in-flight execution.
   * Rejects the pending promise and resets `isLoading` to `false`.
   * The execution token is incremented so any stale in-flight callback is ignored.
   */
  cancel(): void
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export function useEventReply<T = unknown, P extends object | void = object>(
  eventName: string,
  options?: UseEventReplyOptions<T>
): UseEventReplyReturn<T, P> {
  // Graceful degradation: works without LiveSvelte context (SSR, tests without mock).
  let liveCtx: ReturnType<typeof useLiveSvelte> | null = null
  try {
    liveCtx = useLiveSvelte()
  } catch {
    // SSR or test without LiveSvelte context — pushEvent unavailable.
  }

  // Core reactive stores.
  const dataStore: Writable<T | null> = writable(options?.defaultValue ?? null)
  const isLoadingStore: Writable<boolean> = writable(false)

  // Execution-token counter — incremented on each new execution or cancellation.
  // Used to ignore stale callbacks from previous (superseded) executions.
  let executionToken = 0

  // Stored so cancel() can reject the pending promise.
  let pendingReject: ((err: Error) => void) | null = null

  function execute(params?: P): Promise<T> {
    if (get(isLoadingStore)) {
      console.warn(
        `useEventReply: "${eventName}" is already executing. Call cancel() first.`
      )
      return Promise.reject(
        new Error(`useEventReply: "${eventName}" is already executing`)
      )
    }

    if (!liveCtx) {
      return Promise.reject(
        new Error(
          `useEventReply: no LiveSvelte context — "${eventName}" must be called inside a LiveSvelte-mounted component`
        )
      )
    }

    isLoadingStore.set(true)
    const currentToken = ++executionToken

    return new Promise<T>((resolve, reject) => {
      pendingReject = reject

      // Optional timeout: reject if the LiveView hasn't replied in time.
      let timeoutId: ReturnType<typeof setTimeout> | undefined
      if (options?.timeout != null) {
        timeoutId = setTimeout(() => {
          if (currentToken === executionToken) {
            executionToken++
            isLoadingStore.set(false)
            pendingReject = null
            reject(
              new Error(
                `useEventReply: "${eventName}" timed out after ${options.timeout}ms`
              )
            )
          }
        }, options.timeout)
      }

      liveCtx!.pushEvent(
        eventName,
        (params as object | undefined) ?? {},
        (reply: unknown, _ref: number) => {
          // Only update state if this is still the current execution.
          if (currentToken === executionToken) {
            if (timeoutId != null) clearTimeout(timeoutId)
            const typedReply = reply as T
            const updated = options?.updateData
              ? options.updateData(typedReply, get(dataStore))
              : typedReply
            dataStore.set(updated)
            isLoadingStore.set(false)
            pendingReject = null
            resolve(typedReply)
          }
          // Token mismatch: execution was cancelled — ignore stale reply.
        }
      )
    })
  }

  function cancel(): void {
    if (pendingReject) {
      pendingReject(new Error(`useEventReply: "${eventName}" was cancelled`))
      pendingReject = null
    }
    // Increment token to invalidate any in-flight callbacks.
    executionToken++
    isLoadingStore.set(false)
  }

  // Auto-cancel on component destroy to prevent dangling promises.
  onDestroy(() => cancel())

  return {
    data: { subscribe: dataStore.subscribe },
    isLoading: { subscribe: isLoadingStore.subscribe },
    execute,
    cancel,
  }
}
