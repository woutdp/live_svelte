/**
 * Tests for useEventReply composable.
 *
 * Mocking strategy:
 *   - `svelte` module is mocked: getContext (for useLiveSvelte), onDestroy (capture cleanup).
 *     vi.mock is hoisted before imports.
 *   - onDestroy does NOT auto-invoke — tests capture it and call manually when needed.
 *   - mockPushEvent captures the reply callback so tests can simulate server replies.
 *   - jsdom environment (from vitest.config.js) is sufficient — no DOM setup needed
 *     since useEventReply has no DOM operations.
 */

import { vi, describe, it, expect, beforeEach } from "vitest"
import { get } from "svelte/store"

// CRITICAL: vi.mock is hoisted before imports by Vitest. Must appear before
// any import of the module under test.
vi.mock("svelte", () => ({
  getContext: vi.fn(),
  onDestroy: vi.fn(),
}))

import { getContext, onDestroy } from "svelte"
import { useEventReply } from "./useEventReply"
import type { UseEventReplyOptions } from "./useEventReply"

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

// Captures the last pushEvent reply callback so tests can trigger server replies.
let lastReplyCallback: ((reply: unknown, ref: number) => void) | null = null

const mockPushEvent = vi
  .fn()
  .mockImplementation(
    (
      _event: string,
      _params: object,
      callback: (reply: unknown, ref: number) => void
    ) => {
      lastReplyCallback = callback
      return 1
    }
  )

const mockLive = {
  pushEvent: mockPushEvent,
  pushEventTo: vi.fn(),
  handleEvent: vi.fn().mockReturnValue(() => {}),
  removeHandleEvent: vi.fn(),
  upload: vi.fn(),
  uploadTo: vi.fn(),
  liveSocket: undefined,
}

// ---------------------------------------------------------------------------
// Setup / teardown
// ---------------------------------------------------------------------------

beforeEach(() => {
  vi.clearAllMocks()
  lastReplyCallback = null
  vi.mocked(getContext).mockReturnValue(mockLive)
})

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

describe("initialization", () => {
  it("returns all expected properties", () => {
    const result = useEventReply("compute")
    expect(result).toHaveProperty("data")
    expect(result).toHaveProperty("isLoading")
    expect(result).toHaveProperty("execute")
    expect(result).toHaveProperty("cancel")
  })

  it("data store initializes to null when no defaultValue provided", () => {
    const { data } = useEventReply("compute")
    expect(get(data)).toBeNull()
  })

  it("data store initializes to defaultValue when provided", () => {
    const { data } = useEventReply("compute", { defaultValue: { result: 0 } })
    expect(get(data)).toEqual({ result: 0 })
  })

  it("isLoading store initializes to false", () => {
    const { isLoading } = useEventReply("compute")
    expect(get(isLoading)).toBe(false)
  })

  it("registers onDestroy cleanup during init", () => {
    useEventReply("compute")
    expect(vi.mocked(onDestroy)).toHaveBeenCalledTimes(1)
    expect(typeof vi.mocked(onDestroy).mock.calls[0][0]).toBe("function")
  })
})

// ---------------------------------------------------------------------------
// execute() — happy path
// ---------------------------------------------------------------------------

describe("execute()", () => {
  it("returns a Promise", () => {
    const { execute } = useEventReply("compute")
    const result = execute({})
    expect(result).toBeInstanceOf(Promise)
    // Prevent unhandled rejection in test environment.
    result.catch(() => {})
  })

  it("sets isLoading to true immediately when called", () => {
    const { isLoading, execute } = useEventReply("compute")
    const promise = execute({})
    expect(get(isLoading)).toBe(true)
    promise.catch(() => {})
  })

  it("calls pushEvent with the event name and params", () => {
    const { execute } = useEventReply("compute")
    execute({ value: 42 })
    expect(mockPushEvent).toHaveBeenCalledWith(
      "compute",
      { value: 42 },
      expect.any(Function)
    )
  })

  it("calls pushEvent with empty object when no params given", () => {
    const { execute } = useEventReply("compute")
    execute()
    expect(mockPushEvent).toHaveBeenCalledWith("compute", {}, expect.any(Function))
  })

  it("resolves with reply payload from server", async () => {
    const { execute } = useEventReply<{ result: number }>("compute")
    const promise = execute({ value: 21 })

    expect(lastReplyCallback).not.toBeNull()
    lastReplyCallback!({ result: 42 }, 1)

    const reply = await promise
    expect(reply).toEqual({ result: 42 })
  })

  it("updates data store when reply arrives", async () => {
    const { data, execute } = useEventReply<{ result: number }>("compute")
    const promise = execute({})

    lastReplyCallback!({ result: 99 }, 1)
    await promise

    expect(get(data)).toEqual({ result: 99 })
  })

  it("sets isLoading to false after reply", async () => {
    const { isLoading, execute } = useEventReply("compute")
    const promise = execute({})
    expect(get(isLoading)).toBe(true)

    lastReplyCallback!({ result: 1 }, 1)
    await promise

    expect(get(isLoading)).toBe(false)
  })

  it("applies updateData transformer before storing reply", async () => {
    const options: UseEventReplyOptions<{ total: number }> = {
      defaultValue: { total: 0 },
      updateData: (reply, current) => ({ total: (current?.total ?? 0) + reply.total }),
    }
    const { data, execute } = useEventReply<{ total: number }>("accumulate", options)
    const p1 = execute({})
    lastReplyCallback!({ total: 10 }, 1)
    await p1

    const p2 = execute({})
    lastReplyCallback!({ total: 5 }, 1)
    await p2

    expect(get(data)).toEqual({ total: 15 })
  })
})

// ---------------------------------------------------------------------------
// execute() — already loading guard
// ---------------------------------------------------------------------------

describe("execute() while already loading", () => {
  it("rejects if already executing", async () => {
    const { execute } = useEventReply("compute")
    execute({}) // First call — in flight

    await expect(execute({})).rejects.toThrow("is already executing")
  })

  it("logs a console.warn when already executing", () => {
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {})
    try {
      const { execute } = useEventReply("compute")
      execute({})
      execute({}).catch(() => {})
      expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining("already executing"))
    } finally {
      warnSpy.mockRestore()
    }
  })

  it("does not call pushEvent a second time when already loading", () => {
    const { execute } = useEventReply("compute")
    execute({})
    execute({}).catch(() => {})
    expect(mockPushEvent).toHaveBeenCalledTimes(1)
  })
})

// ---------------------------------------------------------------------------
// cancel()
// ---------------------------------------------------------------------------

describe("cancel()", () => {
  it("rejects the pending promise", async () => {
    const { execute, cancel } = useEventReply("compute")
    const promise = execute({})
    cancel()
    await expect(promise).rejects.toThrow("was cancelled")
  })

  it("resets isLoading to false", () => {
    const { isLoading, execute, cancel } = useEventReply("compute")
    const p = execute({})
    p.catch(() => {})
    expect(get(isLoading)).toBe(true)
    cancel()
    expect(get(isLoading)).toBe(false)
  })

  it("stale reply callback is ignored after cancel", async () => {
    const { data, execute, cancel } = useEventReply<{ result: number }>("compute")
    const promise = execute({})
    // Attach catch handler BEFORE cancel() to prevent unhandled rejection.
    const handled = promise.catch(() => {})
    const capturedCallback = lastReplyCallback

    cancel()

    // Try to invoke the stale callback — should be ignored.
    capturedCallback!({ result: 99 }, 1)

    // data store should remain unchanged.
    expect(get(data)).toBeNull()

    await handled
  })

  it("cancel() does nothing when not executing", () => {
    const { isLoading, cancel } = useEventReply("compute")
    expect(() => cancel()).not.toThrow()
    expect(get(isLoading)).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// Timeout option
// ---------------------------------------------------------------------------

describe("timeout option", () => {
  it("rejects promise after timeout elapses", async () => {
    vi.useFakeTimers()
    try {
      const { execute } = useEventReply("slow-event", { timeout: 500 })
      const promise = execute({})
      vi.advanceTimersByTime(501)
      await expect(promise).rejects.toThrow("timed out after 500ms")
    } finally {
      vi.useRealTimers()
    }
  })

  it("resets isLoading after timeout", async () => {
    vi.useFakeTimers()
    try {
      const { isLoading, execute } = useEventReply("slow-event", { timeout: 300 })
      const promise = execute({})
      expect(get(isLoading)).toBe(true)
      vi.advanceTimersByTime(301)
      expect(get(isLoading)).toBe(false)
      await promise.catch(() => {})
    } finally {
      vi.useRealTimers()
    }
  })

  it("does NOT reject if reply arrives before timeout", async () => {
    vi.useFakeTimers()
    try {
      const { execute } = useEventReply<{ result: number }>("fast-event", { timeout: 1000 })
      const promise = execute({})
      // Reply arrives before timeout.
      lastReplyCallback!({ result: 7 }, 1)
      vi.advanceTimersByTime(999)
      const reply = await promise
      expect(reply).toEqual({ result: 7 })
    } finally {
      vi.useRealTimers()
    }
  })

  it("data store is unchanged after timeout", async () => {
    vi.useFakeTimers()
    try {
      const { data, execute } = useEventReply<{ result: number }>("slow-event", {
        defaultValue: { result: 0 },
        timeout: 500,
      })
      const promise = execute({})
      vi.advanceTimersByTime(501)
      await promise.catch(() => {})
      expect(get(data)).toEqual({ result: 0 })
    } finally {
      vi.useRealTimers()
    }
  })

  it("stale timeout callback is ignored after cancel", async () => {
    vi.useFakeTimers()
    try {
      const { data, execute, cancel } = useEventReply<{ result: number }>("slow-event", {
        timeout: 500,
      })
      const promise = execute({})
      cancel()
      vi.advanceTimersByTime(501)
      // Should not throw or update state.
      expect(get(data)).toBeNull()
      await promise.catch(() => {})
    } finally {
      vi.useRealTimers()
    }
  })
})

// ---------------------------------------------------------------------------
// onDestroy cleanup
// ---------------------------------------------------------------------------

describe("onDestroy cleanup", () => {
  it("cancels any pending execution when component is destroyed", () => {
    const { isLoading, execute } = useEventReply("compute")
    const destroyFn = vi.mocked(onDestroy).mock.calls[0][0] as () => void

    const p = execute({})
    p.catch(() => {})
    expect(get(isLoading)).toBe(true)

    destroyFn()
    expect(get(isLoading)).toBe(false)
  })

  it("rejects pending promise on destroy", async () => {
    const { execute } = useEventReply("compute")
    const destroyFn = vi.mocked(onDestroy).mock.calls[0][0] as () => void

    const promise = execute({})
    destroyFn()

    await expect(promise).rejects.toThrow("was cancelled")
  })
})

// ---------------------------------------------------------------------------
// Graceful degradation without LiveSvelte context
// ---------------------------------------------------------------------------

describe("graceful degradation without LiveSvelte context", () => {
  beforeEach(() => {
    vi.mocked(getContext).mockReturnValue(null)
  })

  it("initialises without throwing when context is absent", () => {
    expect(() => useEventReply("compute")).not.toThrow()
  })

  it("execute() returns a rejected promise when context is absent", async () => {
    const { execute } = useEventReply("compute")
    await expect(execute({})).rejects.toThrow("no LiveSvelte context")
  })

  it("does not call pushEvent when context is absent", async () => {
    const { execute } = useEventReply("compute")
    await execute({}).catch(() => {})
    expect(mockPushEvent).not.toHaveBeenCalled()
  })

  it("data and isLoading stores still work without live context", () => {
    const { data, isLoading } = useEventReply("compute", { defaultValue: { x: 1 } })
    expect(get(data)).toEqual({ x: 1 })
    expect(get(isLoading)).toBe(false)
  })

  it("cancel() does not throw when context is absent", () => {
    const { cancel } = useEventReply("compute")
    expect(() => cancel()).not.toThrow()
  })
})
