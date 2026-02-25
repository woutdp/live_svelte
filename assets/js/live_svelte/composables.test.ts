/**
 * Unit tests for LiveSvelte composables.
 * Uses vi.mock to intercept getContext/onDestroy calls (called during component init).
 */
import { vi, describe, it, expect, beforeEach, afterEach } from "vitest"

// Mock svelte BEFORE importing composables (hoisted by vitest)
vi.mock("svelte", () => ({
  getContext: vi.fn(),
  onDestroy: vi.fn(),
}))

import { getContext, onDestroy } from "svelte"
import {
  useLiveSvelte,
  useLiveEvent,
  useLiveConnection,
  useLiveNavigation,
  LIVE_SYMBOL,
  CONNECTION_SYMBOL,
} from "./composables"
import type { Live } from "./types"

const mockLiveSocket = {
  pushHistoryPatch: vi.fn(),
  historyRedirect: vi.fn(),
}

const mockLive: Live = {
  pushEvent: vi.fn().mockReturnValue(1),
  pushEventTo: vi.fn().mockReturnValue(2),
  handleEvent: vi.fn().mockReturnValue(() => {}),
  removeHandleEvent: vi.fn(),
  upload: vi.fn(),
  uploadTo: vi.fn(),
  liveSocket: mockLiveSocket,
}

beforeEach(() => {
  vi.clearAllMocks()
})

// ---------------------------------------------------------------------------
// useLiveSvelte
// ---------------------------------------------------------------------------

describe("useLiveSvelte", () => {
  it("returns live ref from context", () => {
    vi.mocked(getContext).mockReturnValue(mockLive)
    const result = useLiveSvelte()
    expect(getContext).toHaveBeenCalledWith(LIVE_SYMBOL)
    expect(result.live).toBe(mockLive)
  })

  it("throws when context is not set", () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    expect(() => useLiveSvelte()).toThrow("useLiveSvelte()")
  })

  it("pushEvent delegates to live.pushEvent", () => {
    vi.mocked(getContext).mockReturnValue(mockLive)
    const result = useLiveSvelte()
    result.pushEvent("my_event", { key: "val" })
    expect(mockLive.pushEvent).toHaveBeenCalledWith("my_event", { key: "val" })
  })

  it("pushEventTo delegates to live.pushEventTo", () => {
    vi.mocked(getContext).mockReturnValue(mockLive)
    const result = useLiveSvelte()
    result.pushEventTo("#target", "my_event", { key: "val" })
    expect(mockLive.pushEventTo).toHaveBeenCalledWith("#target", "my_event", { key: "val" })
  })

  it("pushEvent returns ref number from live.pushEvent", () => {
    vi.mocked(mockLive.pushEvent).mockReturnValue(42)
    vi.mocked(getContext).mockReturnValue(mockLive)
    const result = useLiveSvelte()
    const ref = result.pushEvent("evt", {})
    expect(ref).toBe(42)
  })
})

// ---------------------------------------------------------------------------
// useLiveEvent
// ---------------------------------------------------------------------------

describe("useLiveEvent", () => {
  it("throws when called outside LiveSvelte context", () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    expect(() => useLiveEvent("some_event", vi.fn())).toThrow("useLiveEvent()")
  })

  it("calls live.handleEvent with the event name and callback", () => {
    vi.mocked(getContext).mockReturnValue(mockLive)
    const cb = vi.fn()
    useLiveEvent("server_event", cb)
    expect(mockLive.handleEvent).toHaveBeenCalledWith("server_event", cb)
  })

  it("registers cleanup via onDestroy", () => {
    const cleanupFn = vi.fn()
    vi.mocked(mockLive.handleEvent).mockReturnValue(cleanupFn)
    vi.mocked(getContext).mockReturnValue(mockLive)
    useLiveEvent("server_event", vi.fn())
    expect(onDestroy).toHaveBeenCalledWith(cleanupFn)
  })

  it("cleanup fn returned by handleEvent is passed to onDestroy", () => {
    const cleanup = vi.fn()
    vi.mocked(mockLive.handleEvent).mockReturnValue(cleanup)
    vi.mocked(getContext).mockReturnValue(mockLive)
    useLiveEvent("server_event", vi.fn())
    const registeredCleanup = vi.mocked(onDestroy).mock.calls[0][0] as () => void
    registeredCleanup()
    expect(cleanup).toHaveBeenCalledOnce()
  })
})

// ---------------------------------------------------------------------------
// useLiveConnection
// ---------------------------------------------------------------------------

describe("useLiveConnection", () => {
  it("reads connected from context state", () => {
    const fakeState = { connected: true }
    vi.mocked(getContext).mockImplementation((key) => {
      if (key === CONNECTION_SYMBOL) return fakeState
      return undefined
    })
    const conn = useLiveConnection()
    expect(conn.connected).toBe(true)
  })

  it("reflects state changes via getter", () => {
    const fakeState = { connected: true }
    vi.mocked(getContext).mockImplementation((key) => {
      if (key === CONNECTION_SYMBOL) return fakeState
      return undefined
    })
    const conn = useLiveConnection()
    fakeState.connected = false
    expect(conn.connected).toBe(false)
  })

  it("returns connected: true when no context present (fallback)", () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    const conn = useLiveConnection()
    expect(conn.connected).toBe(true)
  })

  it("calls getContext with CONNECTION_SYMBOL", () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    useLiveConnection()
    expect(getContext).toHaveBeenCalledWith(CONNECTION_SYMBOL)
  })
})

// ---------------------------------------------------------------------------
// useLiveNavigation
// ---------------------------------------------------------------------------

describe("useLiveNavigation", () => {
  beforeEach(() => {
    vi.stubGlobal("location", { pathname: "/current-path" })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it("throws when live context is absent", () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    expect(() => useLiveNavigation()).toThrow("useLiveNavigation()")
  })

  it("throws when liveSocket is not available", () => {
    const liveWithoutSocket: Live = { ...mockLive, liveSocket: undefined }
    vi.mocked(getContext).mockReturnValue(liveWithoutSocket)
    expect(() => useLiveNavigation()).toThrow("LiveSocket not initialized")
  })

  describe("patch()", () => {
    beforeEach(() => {
      vi.mocked(getContext).mockReturnValue(mockLive)
    })

    it("calls pushHistoryPatch with string href and push by default", () => {
      const { patch } = useLiveNavigation()
      patch("/new-path")
      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/new-path",
        "push",
        null
      )
    })

    it("calls pushHistoryPatch with replace kind when replace: true", () => {
      const { patch } = useLiveNavigation()
      patch("/new-path", { replace: true })
      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/new-path",
        "replace",
        null
      )
    })

    it("builds href from query params object using current pathname", () => {
      const { patch } = useLiveNavigation()
      patch({ page: "2", filter: "active" })
      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?page=2&filter=active",
        "push",
        null
      )
    })

    it("builds href from query params object with replace option", () => {
      const { patch } = useLiveNavigation()
      patch({ search: "test" }, { replace: true })
      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?search=test",
        "replace",
        null
      )
    })
  })

  describe("navigate()", () => {
    beforeEach(() => {
      vi.mocked(getContext).mockReturnValue(mockLive)
    })

    it("calls historyRedirect with href and push by default", () => {
      const { navigate } = useLiveNavigation()
      navigate("/other-live-view")
      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        "/other-live-view",
        "push",
        null,
        null
      )
    })

    it("calls historyRedirect with replace kind when replace: true", () => {
      const { navigate } = useLiveNavigation()
      navigate("/other-live-view", { replace: true })
      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        "/other-live-view",
        "replace",
        null,
        null
      )
    })
  })
})
