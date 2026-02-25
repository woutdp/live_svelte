/**
 * Tests for useLiveUpload composable.
 *
 * Mocking strategy:
 *   - `svelte` module is mocked: getContext (for useLiveSvelte), onMount (auto-invoke callback),
 *     onDestroy (no-op). vi.mock is hoisted before imports.
 *   - The onMount mock invokes the callback immediately (synchronous) so DOM operations
 *     execute during each test without needing a real Svelte component lifecycle.
 *   - jsdom environment (from vitest.config.js) provides document.createElement, DataTransfer, etc.
 */

import { vi, describe, it, expect, beforeEach, afterEach } from "vitest"
import { get } from "svelte/store"

// jsdom does not implement DataTransfer. Polyfill it so addFiles() tests can run.
if (typeof DataTransfer === "undefined") {
  class MockDataTransfer {
    private _files: File[] = []
    items = {
      add: (file: File) => {
        this._files.push(file)
      },
    }
    get files(): FileList {
      const arr = this._files
      return Object.assign(arr, {
        item: (i: number) => arr[i] ?? null,
      }) as unknown as FileList
    }
  }
  ;(globalThis as any).DataTransfer = MockDataTransfer
}

// CRITICAL: vi.mock is hoisted before imports by Vitest. Must appear before
// any import of the module under test.
vi.mock("svelte", () => ({
  getContext: vi.fn(),
  onMount: vi.fn((fn: () => (() => void) | void) => {
    const cleanup = fn()
    // Store cleanup on the mock for explicit teardown in tests if needed.
    ;(vi.mocked(onMount) as any).__lastCleanup = cleanup
  }),
  onDestroy: vi.fn(),
}))

import { getContext, onMount } from "svelte"
import { useLiveUpload } from "./useLiveUpload"
import type { UploadConfig, UploadEntry } from "./useLiveUpload"

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const mockEl = document.createElement("div")
document.body.appendChild(mockEl)

const mockPushEvent = vi.fn().mockReturnValue(1)
const mockLive = {
  pushEvent: mockPushEvent,
  pushEventTo: vi.fn(),
  handleEvent: vi.fn().mockReturnValue(() => {}),
  removeHandleEvent: vi.fn(),
  upload: vi.fn(),
  uploadTo: vi.fn(),
  liveSocket: undefined,
  el: mockEl,
}

function makeEntry(partial: Partial<UploadEntry> = {}): UploadEntry {
  return {
    ref: "e1",
    client_name: "test.txt",
    client_size: 1024,
    client_type: "text/plain",
    progress: 0,
    done: false,
    valid: true,
    preflighted: false,
    errors: [],
    ...partial,
  }
}

const baseConfig: UploadConfig = {
  ref: "phx-ref-0",
  name: "avatar",
  accept: ".jpg,.png",
  max_entries: 1,
  auto_upload: false,
  entries: [],
  errors: [],
}

// ---------------------------------------------------------------------------
// Setup / teardown
// ---------------------------------------------------------------------------

beforeEach(() => {
  vi.clearAllMocks()
  vi.mocked(getContext).mockReturnValue(mockLive)
  // Clear children of mockEl between tests.
  mockEl.innerHTML = ""
  ;(vi.mocked(onMount) as any).__lastCleanup = undefined
})

afterEach(() => {
  // Run cleanup function if the onMount callback returned one.
  const cleanup = (vi.mocked(onMount) as any).__lastCleanup
  if (typeof cleanup === "function") cleanup()
})

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

describe("initialization", () => {
  it("returns all expected properties", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(upload).toHaveProperty("entries")
    expect(upload).toHaveProperty("progress")
    expect(upload).toHaveProperty("valid")
    expect(upload).toHaveProperty("inputEl")
    expect(upload).toHaveProperty("showFilePicker")
    expect(upload).toHaveProperty("addFiles")
    expect(upload).toHaveProperty("submit")
    expect(upload).toHaveProperty("cancel")
    expect(upload).toHaveProperty("clear")
    expect(upload).toHaveProperty("sync")
  })

  it("onMount is called during composable initialisation", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(vi.mocked(onMount)).toHaveBeenCalledTimes(1)
  })

  it("creates hidden form appended to live.el", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const form = mockEl.querySelector("form")
    expect(form).not.toBeNull()
    expect(form?.style.display).toBe("none")
  })

  it("creates input with required Phoenix upload attributes", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input).not.toBeNull()
    expect(input.id).toBe(baseConfig.ref)
    expect(input.name).toBe(baseConfig.name)
    expect(input.getAttribute("data-phx-hook")).toBe("Phoenix.LiveFileUpload")
    expect(input.getAttribute("data-phx-update")).toBe("ignore")
    expect(input.getAttribute("data-phx-upload-ref")).toBe(baseConfig.ref)
  })

  it("sets accept attribute when config.accept is a string", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.accept).toBe(".jpg,.png")
  })

  it("does NOT set accept attribute when config.accept is false", () => {
    const config = { ...baseConfig, accept: false as const }
    useLiveUpload(config, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.accept).toBe("")
  })

  it("sets multiple attribute when max_entries > 1", () => {
    const config = { ...baseConfig, max_entries: 3 }
    useLiveUpload(config, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.multiple).toBe(true)
  })

  it("does NOT set multiple when max_entries = 1", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.multiple).toBe(false)
  })

  it("sets data-phx-auto-upload when auto_upload is true", () => {
    const config = { ...baseConfig, auto_upload: true }
    useLiveUpload(config, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.getAttribute("data-phx-auto-upload")).toBe("true")
  })

  it("does NOT set data-phx-auto-upload when auto_upload is false", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = mockEl.querySelector("input[type=file]") as HTMLInputElement
    expect(input.getAttribute("data-phx-auto-upload")).toBeNull()
  })

  it("sets phx-change on form when changeEvent is provided", () => {
    useLiveUpload(baseConfig, { changeEvent: "validate", submitEvent: "save" })
    const form = mockEl.querySelector("form")
    expect(form?.getAttribute("phx-change")).toBe("validate")
  })

  it("does NOT set phx-change on form when changeEvent is omitted", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const form = mockEl.querySelector("form")
    expect(form?.getAttribute("phx-change")).toBeNull()
  })

  it("sets phx-submit on form", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    const form = mockEl.querySelector("form")
    expect(form?.getAttribute("phx-submit")).toBe("save")
  })

  it("exposes inputEl store with the created input element", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)
    expect(input).not.toBeNull()
    expect(input?.tagName).toBe("INPUT")
  })
})

// ---------------------------------------------------------------------------
// Reactive stores — initial state
// ---------------------------------------------------------------------------

describe("reactive stores — initial state", () => {
  it("entries store is empty initially", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.entries)).toEqual([])
  })

  it("progress returns 0 when there are no entries", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.progress)).toBe(0)
  })

  it("valid returns true when errors is empty", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.valid)).toBe(true)
  })

  it("valid returns false when config has top-level errors", () => {
    const config = { ...baseConfig, errors: [{ ref: "phx-ref-0", error: "too many files" }] }
    const upload = useLiveUpload(config, { submitEvent: "save" })
    expect(get(upload.valid)).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// sync()
// ---------------------------------------------------------------------------

describe("sync()", () => {
  it("updates entries store when new config has entries", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const entry = makeEntry({ client_name: "img.jpg", progress: 50 })
    upload.sync({ ...baseConfig, entries: [entry] })
    expect(get(upload.entries)).toHaveLength(1)
    expect(get(upload.entries)[0].client_name).toBe("img.jpg")
  })

  it("clears entries when synced with empty entries", () => {
    const entry = makeEntry()
    const configWithEntry = { ...baseConfig, entries: [entry] }
    const upload = useLiveUpload(configWithEntry, { submitEvent: "save" })
    upload.sync(baseConfig)
    expect(get(upload.entries)).toHaveLength(0)
  })

  it("updates progress after sync", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    upload.sync({
      ...baseConfig,
      entries: [
        makeEntry({ ref: "e1", progress: 60 }),
        makeEntry({ ref: "e2", progress: 40 }),
      ],
    })
    expect(get(upload.progress)).toBe(50)
  })

  it("rounds fractional progress", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    upload.sync({
      ...baseConfig,
      entries: [
        makeEntry({ ref: "e1", progress: 33 }),
        makeEntry({ ref: "e2", progress: 34 }),
        makeEntry({ ref: "e3", progress: 34 }),
      ],
    })
    // (33+34+34)/3 = 33.666... → rounds to 34
    expect(get(upload.progress)).toBe(34)
  })

  it("updates valid after sync changes errors", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.valid)).toBe(true)
    upload.sync({ ...baseConfig, errors: [{ ref: "phx-ref-0", error: "too large" }] })
    expect(get(upload.valid)).toBe(false)
  })

  it("updates input ref attributes when entries change", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    expect(input.getAttribute("data-phx-active-refs")).toBe("")
    const entry = makeEntry({ ref: "e99", done: false, preflighted: false })
    upload.sync({ ...baseConfig, entries: [entry] })
    expect(input.getAttribute("data-phx-active-refs")).toBe("e99")
  })

  it("sets data-phx-done-refs from done entries", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    const entry = makeEntry({ ref: "e1", done: true })
    upload.sync({ ...baseConfig, entries: [entry] })
    expect(input.getAttribute("data-phx-done-refs")).toBe("e1")
  })

  it("sets data-phx-preflighted-refs from preflighted entries", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    const entry = makeEntry({ ref: "e1", preflighted: true })
    upload.sync({ ...baseConfig, entries: [entry] })
    expect(input.getAttribute("data-phx-preflighted-refs")).toBe("e1")
  })
})

// ---------------------------------------------------------------------------
// showFilePicker()
// ---------------------------------------------------------------------------

describe("showFilePicker()", () => {
  it("calls click() on the hidden input", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    const clickSpy = vi.spyOn(input, "click")
    upload.showFilePicker()
    expect(clickSpy).toHaveBeenCalledTimes(1)
  })
})

// ---------------------------------------------------------------------------
// addFiles()
// ---------------------------------------------------------------------------

describe("addFiles()", () => {
  // jsdom does not support assigning arbitrary FileList to input.files.
  // We override the files property on the specific input element to make it
  // writable before calling addFiles(), then verify the change event fires.

  it("accepts an array of File objects and dispatches change event", () => {
    vi.useFakeTimers()
    try {
      const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
      const input = get(upload.inputEl)!
      // Make files writable on this instance so jsdom doesn't throw.
      Object.defineProperty(input, "files", { writable: true, configurable: true, value: null })
      const dispatchSpy = vi.spyOn(input, "dispatchEvent")
      const file = new File(["content"], "test.txt", { type: "text/plain" })
      upload.addFiles([file])
      vi.runAllTimers()
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({ type: "change", bubbles: true })
      )
    } finally {
      vi.useRealTimers()
    }
  })

  it("accepts a DataTransfer object and dispatches change event", () => {
    vi.useFakeTimers()
    try {
      const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
      const input = get(upload.inputEl)!
      Object.defineProperty(input, "files", { writable: true, configurable: true, value: null })
      const dispatchSpy = vi.spyOn(input, "dispatchEvent")
      const dt = new DataTransfer()
      dt.items.add(new File(["content"], "file.png", { type: "image/png" }))
      upload.addFiles(dt)
      vi.runAllTimers()
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({ type: "change", bubbles: true })
      )
    } finally {
      vi.useRealTimers()
    }
  })

  it("does NOT dispatch change event when DataTransfer is unavailable", () => {
    vi.stubGlobal("DataTransfer", undefined)
    vi.useFakeTimers()
    try {
      const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
      const input = get(upload.inputEl)!
      const dispatchSpy = vi.spyOn(input, "dispatchEvent")
      upload.addFiles([new File(["content"], "test.txt")])
      vi.runAllTimers()
      expect(dispatchSpy).not.toHaveBeenCalled()
    } finally {
      vi.useRealTimers()
      vi.unstubAllGlobals()
    }
  })
})

// ---------------------------------------------------------------------------
// submit()
// ---------------------------------------------------------------------------

describe("submit()", () => {
  it("dispatches submit event on the form", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    const form = input.form!
    const dispatchSpy = vi.spyOn(form, "dispatchEvent")
    upload.submit()
    expect(dispatchSpy).toHaveBeenCalledWith(
      expect.objectContaining({ type: "submit", bubbles: true })
    )
  })
})

// ---------------------------------------------------------------------------
// cancel()
// ---------------------------------------------------------------------------

describe("cancel()", () => {
  it("cancel(ref) calls pushEvent with cancel-upload and the ref", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    upload.cancel("e1")
    expect(mockPushEvent).toHaveBeenCalledWith("cancel-upload", { ref: "e1" })
  })

  it("cancel() without args cancels all current entries", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    upload.sync({
      ...baseConfig,
      entries: [makeEntry({ ref: "e1" }), makeEntry({ ref: "e2" })],
    })
    upload.cancel()
    expect(mockPushEvent).toHaveBeenCalledTimes(2)
    expect(mockPushEvent).toHaveBeenCalledWith("cancel-upload", { ref: "e1" })
    expect(mockPushEvent).toHaveBeenCalledWith("cancel-upload", { ref: "e2" })
  })

  it("cancel() with no entries makes no pushEvent calls", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    upload.cancel()
    expect(mockPushEvent).not.toHaveBeenCalled()
  })
})

// ---------------------------------------------------------------------------
// clear()
// ---------------------------------------------------------------------------

describe("clear()", () => {
  it("resets hidden input value", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    const input = get(upload.inputEl)!
    // Simulate a value being present.
    Object.defineProperty(input, "value", { writable: true, value: "C:\\fakepath\\file.txt" })
    upload.clear()
    expect(input.value).toBe("")
  })
})

// ---------------------------------------------------------------------------
// DOM cleanup on destroy
// ---------------------------------------------------------------------------

describe("DOM cleanup", () => {
  it("removes form from DOM when cleanup is called", () => {
    useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(mockEl.querySelector("form")).not.toBeNull()

    // Run the cleanup function returned by onMount.
    const cleanup = (vi.mocked(onMount) as any).__lastCleanup
    expect(typeof cleanup).toBe("function")
    cleanup()

    expect(mockEl.querySelector("form")).toBeNull()
  })

  it("sets inputEl to null on cleanup", () => {
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.inputEl)).not.toBeNull()

    const cleanup = (vi.mocked(onMount) as any).__lastCleanup
    cleanup()

    expect(get(upload.inputEl)).toBeNull()
  })
})

// ---------------------------------------------------------------------------
// Graceful degradation (no LiveSvelte context)
// ---------------------------------------------------------------------------

describe("graceful degradation without LiveSvelte context", () => {
  it("initialises without throwing when getContext returns null", () => {
    vi.mocked(getContext).mockReturnValue(null)
    expect(() => useLiveUpload(baseConfig, { submitEvent: "save" })).not.toThrow()
  })

  it("does not append form to any element when live context is absent", () => {
    vi.mocked(getContext).mockReturnValue(null)
    useLiveUpload(baseConfig, { submitEvent: "save" })
    // mockEl should have no children since liveCtx is null.
    expect(mockEl.querySelector("form")).toBeNull()
  })

  it("cancel() silently does nothing when context is absent", () => {
    vi.mocked(getContext).mockReturnValue(null)
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(() => upload.cancel("e1")).not.toThrow()
    expect(mockPushEvent).not.toHaveBeenCalled()
  })

  it("stores still work without live context", () => {
    vi.mocked(getContext).mockReturnValue(null)
    const upload = useLiveUpload(baseConfig, { submitEvent: "save" })
    expect(get(upload.entries)).toEqual([])
    expect(get(upload.progress)).toBe(0)
    expect(get(upload.valid)).toBe(true)
    upload.sync({ ...baseConfig, entries: [makeEntry()] })
    expect(get(upload.entries)).toHaveLength(1)
  })
})
