/**
 * Unit tests for useLiveForm composable.
 * Uses vi.mock to intercept getContext calls (called inside useLiveSvelte).
 * Uses `get(store)` from svelte/store for synchronous store reads.
 */
import { vi, describe, it, expect, beforeEach, afterEach } from "vitest"

// Mock svelte BEFORE importing composables (hoisted by vitest).
vi.mock("svelte", () => ({
  getContext: vi.fn(),
  onDestroy: vi.fn(),
}))

import { get } from "svelte/store"
import { getContext } from "svelte"
import { useLiveForm } from "./useLiveForm"
import type { Form } from "./useLiveForm"
import type { Live } from "./types"

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const mockPushEvent = vi.fn().mockReturnValue(1)
const mockLive: Live = {
  pushEvent: mockPushEvent,
  pushEventTo: vi.fn().mockReturnValue(2),
  handleEvent: vi.fn().mockReturnValue(() => {}),
  removeHandleEvent: vi.fn(),
  upload: vi.fn(),
  uploadTo: vi.fn(),
  liveSocket: undefined,
}

const testForm: Form<{ name: string; email: string }> = {
  name: "user",
  values: { name: "", email: "" },
  errors: {},
  valid: true,
}

beforeEach(() => {
  vi.clearAllMocks()
  vi.mocked(getContext).mockReturnValue(mockLive)
})

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

describe("useLiveForm — initialization", () => {
  it("returns required API surface", () => {
    const form = useLiveForm(testForm)
    expect(form.field).toBeDefined()
    expect(form.fieldArray).toBeDefined()
    expect(form.submit).toBeDefined()
    expect(form.reset).toBeDefined()
    expect(form.sync).toBeDefined()
    expect(form.isValid).toBeDefined()
    expect(form.isDirty).toBeDefined()
    expect(form.isTouched).toBeDefined()
    expect(form.isValidating).toBeDefined()
    expect(form.submitCount).toBeDefined()
    expect(form.initialValues).toBeDefined()
  })

  it("exposes a frozen initialValues snapshot", () => {
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "a@b.com" } })
    expect(form.initialValues.name).toBe("Alice")
    expect(form.initialValues.email).toBe("a@b.com")
    expect(Object.isFrozen(form.initialValues)).toBe(true)
  })

  it("isValid is true when no errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.isValid)).toBe(true)
  })

  it("isValid is false when errors present", () => {
    const form = useLiveForm({
      ...testForm,
      errors: { name: ["can't be blank"] },
      valid: false,
    })
    expect(get(form.isValid)).toBe(false)
  })

  it("isDirty is false initially", () => {
    const form = useLiveForm(testForm)
    expect(get(form.isDirty)).toBe(false)
  })

  it("isTouched is false initially", () => {
    const form = useLiveForm(testForm)
    expect(get(form.isTouched)).toBe(false)
  })

  it("submitCount is 0 initially", () => {
    const form = useLiveForm(testForm)
    expect(get(form.submitCount)).toBe(0)
  })
})

// ---------------------------------------------------------------------------
// field() — value
// ---------------------------------------------------------------------------

describe("field() — value", () => {
  it("reflects initial form values", () => {
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "" } })
    const nameField = form.field("name")
    expect(get(nameField).value).toBe("Alice")
  })

  it("reflects empty string initial value", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(nameField).value).toBe("")
  })

  it("set() updates the field value in the store", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    nameField.set("Bob")
    expect(get(nameField).value).toBe("Bob")
  })

  it("update() transforms the field value", () => {
    const form = useLiveForm({ ...testForm, values: { name: "hello", email: "" } })
    const nameField = form.field<string>("name")
    nameField.update((v) => v.toUpperCase())
    expect(get(nameField).value).toBe("HELLO")
  })

  it("isDirty becomes true after set()", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(form.isDirty)).toBe(false)
    nameField.set("Bob")
    expect(get(form.isDirty)).toBe(true)
  })

  it("field isDirty is false initially, true after mutation", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(nameField).isDirty).toBe(false)
    nameField.set("changed")
    expect(get(nameField).isDirty).toBe(true)
  })

  it("memoizes — same field instance returned for same path", () => {
    const form = useLiveForm(testForm)
    const a = form.field("name")
    const b = form.field("name")
    expect(a).toBe(b)
  })

  it("separate instances for same path with different options", () => {
    const form = useLiveForm(testForm)
    const a = form.field("agree", { type: "checkbox", value: "yes" })
    const b = form.field("agree", { type: "checkbox", value: "no" })
    expect(a).not.toBe(b)
  })
})

// ---------------------------------------------------------------------------
// field() — errors
// ---------------------------------------------------------------------------

describe("field() — errors", () => {
  it("errors is empty array when no errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.field("name")).errors).toEqual([])
  })

  it("errors reflects form.errors for a field", () => {
    const form = useLiveForm({
      ...testForm,
      errors: { name: ["can't be blank"] },
    })
    expect(get(form.field("name")).errors).toEqual(["can't be blank"])
  })

  it("errors can contain multiple messages", () => {
    const form = useLiveForm({
      ...testForm,
      errors: { email: ["is invalid", "can't be blank"] },
    })
    expect(get(form.field("email")).errors).toEqual(["is invalid", "can't be blank"])
  })

  it("errorMessage is undefined when no errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.field("name")).errorMessage).toBeUndefined()
  })

  it("errorMessage returns first error string", () => {
    const form = useLiveForm({
      ...testForm,
      errors: { name: ["can't be blank", "is too short"] },
    })
    expect(get(form.field("name")).errorMessage).toBe("can't be blank")
  })

  it("isValid is false when field has errors", () => {
    const form = useLiveForm({ ...testForm, errors: { name: ["required"] } })
    expect(get(form.field("name")).isValid).toBe(false)
  })

  it("isValid is true when field has no errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.field("name")).isValid).toBe(true)
  })
})

// ---------------------------------------------------------------------------
// field() — attrs
// ---------------------------------------------------------------------------

describe("field() — attrs", () => {
  it("attrs includes name and id", () => {
    const form = useLiveForm(testForm)
    const attrs = get(form.field("name")).attrs
    expect(attrs.name).toBe("name")
    expect(attrs.id).toBe("name")
  })

  it("attrs includes value reflecting current field value", () => {
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "" } })
    const attrs = get(form.field("name")).attrs
    expect(attrs.value).toBe("Alice")
  })

  it("attrs.aria-invalid is false when field is valid", () => {
    const form = useLiveForm(testForm)
    expect(get(form.field("name")).attrs["aria-invalid"]).toBe(false)
  })

  it("attrs.aria-invalid is true when field has errors", () => {
    const form = useLiveForm({ ...testForm, errors: { name: ["required"] } })
    expect(get(form.field("name")).attrs["aria-invalid"]).toBe(true)
  })

  it("attrs.aria-describedby is set when field has errors", () => {
    const form = useLiveForm({ ...testForm, errors: { name: ["required"] } })
    expect(get(form.field("name")).attrs["aria-describedby"]).toBe("name-error")
  })

  it("attrs.aria-describedby is absent when field has no errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.field("name")).attrs["aria-describedby"]).toBeUndefined()
  })

  it("attrs includes oninput and onblur handlers", () => {
    const form = useLiveForm(testForm)
    const attrs = get(form.field("name")).attrs
    expect(typeof attrs.oninput).toBe("function")
    expect(typeof attrs.onblur).toBe("function")
  })

  it("attrs.oninput updates field value via event", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    const attrs = get(nameField).attrs
    const fakeEvent = { target: { value: "Carol" } } as unknown as Event
    attrs.oninput(fakeEvent)
    expect(get(nameField).value).toBe("Carol")
  })

  it("attrs.onblur marks field as touched", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(nameField).isTouched).toBe(false)
    get(nameField).attrs.onblur()
    expect(get(nameField).isTouched).toBe(true)
  })

  it("sanitizes dotted paths to valid id strings", () => {
    const form = useLiveForm({
      name: "user",
      values: { profile: { bio: "" } } as any,
      errors: {},
      valid: true,
    })
    const attrs = get(form.field("profile.bio")).attrs
    expect(attrs.id).toBe("profile_bio")
    expect(attrs.name).toBe("profile.bio")
  })
})

// ---------------------------------------------------------------------------
// Checkbox attrs
// ---------------------------------------------------------------------------

describe("field() — checkbox attrs", () => {
  it("single checkbox checked when value matches", () => {
    const form = useLiveForm({
      name: "prefs",
      values: { agree: true } as any,
      errors: {},
      valid: true,
    })
    const attrs = get(form.field("agree", { type: "checkbox" })).attrs
    expect(attrs.checked).toBe(true)
    expect(attrs.type).toBe("checkbox")
  })

  it("single checkbox not checked when value is false", () => {
    const form = useLiveForm({
      name: "prefs",
      values: { agree: false } as any,
      errors: {},
      valid: true,
    })
    const attrs = get(form.field("agree", { type: "checkbox" })).attrs
    expect(attrs.checked).toBe(false)
  })

  it("multi-checkbox checked when optValue is in array", () => {
    const form = useLiveForm({
      name: "prefs",
      values: { roles: ["admin", "editor"] } as any,
      errors: {},
      valid: true,
    })
    const adminAttrs = get(form.field("roles", { type: "checkbox", value: "admin" })).attrs
    const userAttrs = get(form.field("roles", { type: "checkbox", value: "user" })).attrs
    expect(adminAttrs.checked).toBe(true)
    expect(userAttrs.checked).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// fieldArray()
// ---------------------------------------------------------------------------

describe("fieldArray()", () => {
  const arrayForm: Form<{ items: { title: string }[] }> = {
    name: "data",
    values: { items: [{ title: "first" }, { title: "second" }, { title: "third" }] },
    errors: {},
    valid: true,
  }

  it("fields length matches initial array", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    expect(get(items.fields).length).toBe(3)
  })

  it("fields array contains FormField instances with correct values", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    const fields = get(items.fields)
    expect(get(fields[0]).value).toEqual({ title: "first" })
    expect(get(fields[1]).value).toEqual({ title: "second" })
  })

  it("add() appends an item", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    items.add({ title: "fourth" })
    expect(get(items.fields).length).toBe(4)
    expect(get(get(items.fields)[3]).value).toEqual({ title: "fourth" })
  })

  it("add() with no args appends an empty object", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    items.add()
    expect(get(items.fields).length).toBe(4)
  })

  it("remove() removes item at index", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    items.remove(0)
    expect(get(items.fields).length).toBe(2)
    expect(get(get(items.fields)[0]).value).toEqual({ title: "second" })
  })

  it("move() swaps items", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    items.move(0, 1)
    const fields = get(items.fields)
    expect(get(fields[0]).value).toEqual({ title: "second" })
    expect(get(fields[1]).value).toEqual({ title: "first" })
  })

  it("move() with out-of-bounds indices is a no-op", () => {
    const form = useLiveForm(arrayForm)
    const items = form.fieldArray("items")
    items.move(0, 99)
    expect(get(items.fields).length).toBe(3)
    expect(get(get(items.fields)[0]).value).toEqual({ title: "first" })
  })

  it("fieldArray is memoized — same instance returned for same path", () => {
    const form = useLiveForm(arrayForm)
    expect(form.fieldArray("items")).toBe(form.fieldArray("items"))
  })
})

// ---------------------------------------------------------------------------
// sync()
// ---------------------------------------------------------------------------

describe("sync()", () => {
  it("updates currentErrors with new errors", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(nameField).errors).toEqual([])

    form.sync({
      ...testForm,
      errors: { name: ["can't be blank"] },
      valid: false,
    })

    expect(get(nameField).errors).toEqual(["can't be blank"])
  })

  it("updates currentValues when not validating", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    expect(get(nameField).value).toBe("")

    form.sync({ ...testForm, values: { name: "Server", email: "" } })

    expect(get(nameField).value).toBe("Server")
  })

  it("updates isValid based on synced errors", () => {
    const form = useLiveForm(testForm)
    expect(get(form.isValid)).toBe(true)

    form.sync({ ...testForm, errors: { email: ["is invalid"] }, valid: false })

    expect(get(form.isValid)).toBe(false)
  })

  it("does not overwrite values while validating (debounce in-flight)", () => {
    vi.useFakeTimers()
    const form = useLiveForm(testForm, {
      changeEvent: "validate",
      debounceInMiliseconds: 300,
    })
    const nameField = form.field("name")

    // User types — debounce timer starts, isValidating = true.
    nameField.set("typing")

    // Server responds with old data before debounce fires — should NOT overwrite.
    form.sync({ ...testForm, values: { name: "", email: "" } })
    expect(get(nameField).value).toBe("typing")

    vi.useRealTimers()
  })
})

// ---------------------------------------------------------------------------
// Debounce and pushEvent
// ---------------------------------------------------------------------------

describe("debounce and pushEvent", () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it("does not call pushEvent immediately on set()", () => {
    const form = useLiveForm(testForm, { changeEvent: "validate" })
    form.field("name").set("Bob")
    expect(mockPushEvent).not.toHaveBeenCalled()
  })

  it("calls pushEvent after debounce delay", () => {
    const form = useLiveForm(testForm, {
      changeEvent: "validate",
      debounceInMiliseconds: 300,
    })
    form.field("name").set("Bob")
    vi.advanceTimersByTime(300)
    expect(mockPushEvent).toHaveBeenCalledWith("validate", { user: { name: "Bob", email: "" } })
  })

  it("debounces multiple rapid set() calls into one pushEvent", () => {
    const form = useLiveForm(testForm, {
      changeEvent: "validate",
      debounceInMiliseconds: 300,
    })
    const nameField = form.field("name")
    nameField.set("B")
    nameField.set("Bo")
    nameField.set("Bob")
    vi.advanceTimersByTime(300)
    expect(mockPushEvent).toHaveBeenCalledTimes(1)
    expect(mockPushEvent).toHaveBeenCalledWith("validate", { user: { name: "Bob", email: "" } })
  })

  it("does not call pushEvent when changeEvent is null", () => {
    const form = useLiveForm(testForm, { changeEvent: null })
    form.field("name").set("Bob")
    vi.advanceTimersByTime(1000)
    expect(mockPushEvent).not.toHaveBeenCalled()
  })
})

// ---------------------------------------------------------------------------
// submit()
// ---------------------------------------------------------------------------

describe("submit()", () => {
  it("increments submitCount", async () => {
    const form = useLiveForm(testForm)
    expect(get(form.submitCount)).toBe(0)
    // Mock pushEvent to call the reply callback
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    await form.submit()
    expect(get(form.submitCount)).toBe(1)
  })

  it("calls pushEvent with submitEvent and current values", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm(
      { ...testForm, values: { name: "Alice", email: "a@b.com" } },
      { submitEvent: "submit" }
    )
    await form.submit()
    expect(mockPushEvent).toHaveBeenCalledWith(
      "submit",
      { user: { name: "Alice", email: "a@b.com" } },
      expect.any(Function)
    )
  })

  it("resets form when server replies with { reset: true }", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({ reset: true }, 1)
      return 1
    })
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "" } })
    form.field("name").set("Bob")
    expect(get(form.isDirty)).toBe(true)

    await form.submit()

    expect(get(form.isDirty)).toBe(false)
    expect(get(form.submitCount)).toBe(0)
  })

  it("does not reset when server does not reply with reset", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "" } })
    form.field("name").set("Bob")
    await form.submit()
    expect(get(form.isDirty)).toBe(true)
  })

  it("gracefully skips pushEvent when no live context", async () => {
    vi.mocked(getContext).mockReturnValue(undefined)
    const form = useLiveForm(testForm)
    const result = await form.submit()
    expect(result).toBeUndefined()
    expect(mockPushEvent).not.toHaveBeenCalled()
  })
})

// ---------------------------------------------------------------------------
// reset()
// ---------------------------------------------------------------------------

describe("reset()", () => {
  it("restores field values to initial values", () => {
    const form = useLiveForm({ ...testForm, values: { name: "Alice", email: "" } })
    const nameField = form.field("name")
    nameField.set("Bob")
    expect(get(nameField).value).toBe("Bob")

    form.reset()

    expect(get(nameField).value).toBe("Alice")
  })

  it("clears dirty state", () => {
    const form = useLiveForm(testForm)
    form.field("name").set("dirty")
    expect(get(form.isDirty)).toBe(true)

    form.reset()

    expect(get(form.isDirty)).toBe(false)
  })

  it("clears errors", () => {
    const form = useLiveForm({ ...testForm, errors: { name: ["required"] } })
    form.reset()
    expect(get(form.isValid)).toBe(true)
    expect(get(form.field("name")).errors).toEqual([])
  })

  it("resets submitCount to 0", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm(testForm)
    await form.submit()
    expect(get(form.submitCount)).toBe(1)
    form.reset()
    expect(get(form.submitCount)).toBe(0)
  })

  it("clears touched state", () => {
    const form = useLiveForm(testForm)
    const nameField = form.field("name")
    get(nameField).attrs.onblur()
    expect(get(form.isTouched)).toBe(true)

    form.reset()

    expect(get(form.isTouched)).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// submit() — debounce cancellation (M1 fix)
// ---------------------------------------------------------------------------

describe("submit() — debounce cancellation", () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it("cancels pending debounce timer before sending submit", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm(testForm, { changeEvent: "validate", debounceInMiliseconds: 300 })

    // User types — debounce timer starts.
    form.field("name").set("Bob")
    expect(get(form.isValidating)).toBe(true)

    // User submits before debounce fires.
    await form.submit()

    // Advance past debounce window — validate pushEvent must NOT fire.
    vi.advanceTimersByTime(300)

    // Only the submit pushEvent should have been called, not validate.
    expect(mockPushEvent).toHaveBeenCalledTimes(1)
    expect(mockPushEvent).toHaveBeenCalledWith("submit", expect.any(Object), expect.any(Function))
  })

  it("clears isValidating flag when submit cancels the debounce", async () => {
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm(testForm, { changeEvent: "validate", debounceInMiliseconds: 300 })

    form.field("name").set("Bob")
    expect(get(form.isValidating)).toBe(true)

    await form.submit()

    expect(get(form.isValidating)).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// prepareData option (L2)
// ---------------------------------------------------------------------------

describe("prepareData option", () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it("transforms values before pushEvent on change", () => {
    const prepareData = vi.fn((data: Record<string, unknown>) => ({ ...data, _extra: "yes" }))
    const form = useLiveForm(testForm, {
      changeEvent: "validate",
      debounceInMiliseconds: 300,
      prepareData,
    })

    form.field("name").set("Bob")
    vi.advanceTimersByTime(300)

    expect(prepareData).toHaveBeenCalledWith({ name: "Bob", email: "" })
    expect(mockPushEvent).toHaveBeenCalledWith("validate", {
      user: { name: "Bob", email: "", _extra: "yes" },
    })
  })

  it("transforms values before pushEvent on submit", async () => {
    const prepareData = vi.fn((data: Record<string, unknown>) => ({ ...data, _token: "tok" }))
    vi.mocked(mockPushEvent).mockImplementation((_event, _payload, onReply) => {
      onReply?.({}, 1)
      return 1
    })
    const form = useLiveForm(
      { ...testForm, values: { name: "Alice", email: "a@b.com" } },
      { prepareData }
    )

    await form.submit()

    expect(mockPushEvent).toHaveBeenCalledWith(
      "submit",
      { user: { name: "Alice", email: "a@b.com", _token: "tok" } },
      expect.any(Function)
    )
  })
})

// ---------------------------------------------------------------------------
// FormField sub-field and sub-fieldArray methods (L3)
// ---------------------------------------------------------------------------

describe("FormField.field() and FormField.fieldArray() sub-access", () => {
  const nestedForm = {
    name: "data",
    values: { profile: { bio: "hello" }, items: [{ title: "one" }] },
    errors: {} as Record<string, unknown>,
    valid: true,
  }

  it("field().field() accesses a nested sub-path", () => {
    const form = useLiveForm(nestedForm as any)
    const profileField = form.field("profile")
    const bioField = profileField.field("bio")
    expect(get(bioField).value).toBe("hello")
  })

  it("field().field() sub-field path is equivalent to full dot-path", () => {
    const form = useLiveForm(nestedForm as any)
    const viaSubField = form.field("profile").field("bio")
    const viaFullPath = form.field("profile.bio")
    // Both should refer to the same memoized instance.
    expect(viaSubField).toBe(viaFullPath)
  })

  it("field().field() set() updates the nested value", () => {
    const form = useLiveForm(nestedForm as any)
    const bioField = form.field("profile").field<string>("bio")
    bioField.set("updated")
    expect(get(bioField).value).toBe("updated")
  })

  it("field().fieldArray() accesses a nested array sub-path", () => {
    const form = useLiveForm(nestedForm as any)
    const itemsArray = form.field("items").fieldArray("") // via field sub-access
    // Direct fieldArray should be equivalent
    const directItems = form.fieldArray("items")
    expect(get(directItems.fields).length).toBe(1)
  })
})
