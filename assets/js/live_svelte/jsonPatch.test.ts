import { describe, expect, it } from "vitest"
import { applyPatch } from "./jsonPatch.js"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeItem(id: number, extra: Record<string, unknown> = {}) {
  return { id, name: `Item ${id}`, __dom_id: `items-${id}`, ...extra }
}

// ---------------------------------------------------------------------------
// Standard RFC 6902 ops (regression guard)
// ---------------------------------------------------------------------------

describe("standard ops", () => {
  it("replace — sets scalar value", () => {
    const state: Record<string, unknown> = { count: 0 }
    applyPatch(state, [["replace", "/count", 42]])
    expect(state.count).toBe(42)
  })

  it("add — inserts into array at index", () => {
    const state: Record<string, unknown> = { items: [1, 2, 3] }
    applyPatch(state, [["add", "/items/1", 99]])
    expect(state.items).toEqual([1, 99, 2, 3])
  })

  it("remove — deletes by index", () => {
    const state: Record<string, unknown> = { items: [10, 20, 30] }
    applyPatch(state, [["remove", "/items/1"]])
    expect(state.items).toEqual([10, 30])
  })

  it("test op is always skipped", () => {
    const state: Record<string, unknown> = { x: 1 }
    applyPatch(state, [["test", "", 999], ["replace", "/x", 2]])
    expect(state.x).toBe(2)
  })

  it("empty ops array returns state unchanged", () => {
    const state: Record<string, unknown> = { a: 1 }
    applyPatch(state, [])
    expect(state).toEqual({ a: 1 })
  })
})

// ---------------------------------------------------------------------------
// $$dom_id path lookup in resolveKey
// ---------------------------------------------------------------------------

describe("$$dom_id path syntax (remove / replace via dom_id)", () => {
  it("remove with $$dom_id removes matching item", () => {
    const state: Record<string, unknown> = {
      items: [makeItem(1), makeItem(2), makeItem(3)],
    }
    applyPatch(state, [["remove", "/items/$$items-2"]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 3])
  })

  it("remove with $$dom_id on last item", () => {
    const state: Record<string, unknown> = { items: [makeItem(1)] }
    applyPatch(state, [["remove", "/items/$$items-1"]])
    expect(state.items).toEqual([])
  })

  it("remove with unknown $$dom_id is silently skipped", () => {
    const state: Record<string, unknown> = { items: [makeItem(1)] }
    applyPatch(state, [["remove", "/items/$$items-999"]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1])
  })

  it("replace with $$dom_id updates item in place", () => {
    const state: Record<string, unknown> = {
      items: [makeItem(1), makeItem(2)],
    }
    applyPatch(state, [["replace", "/items/$$items-1", makeItem(1, { name: "Updated" })]])
    const items = state.items as { id: number; name: string }[]
    expect(items[0].name).toBe("Updated")
    expect(items.length).toBe(2)
  })

  it("replace with unknown $$dom_id is silently skipped (update_only: true, item absent)", () => {
    const state: Record<string, unknown> = { items: [makeItem(1)] }
    applyPatch(state, [["replace", "/items/$$items-999", makeItem(999, { name: "Ghost" })]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1])
  })
})

// ---------------------------------------------------------------------------
// upsert op
// ---------------------------------------------------------------------------

describe("upsert op", () => {
  it("inserts a new item at index when __dom_id not present", () => {
    const state: Record<string, unknown> = { items: [] }
    applyPatch(state, [["upsert", "/items/-", makeItem(1)]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1])
  })

  it("inserts at -  (end) appends correctly", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2)] }
    applyPatch(state, [["upsert", "/items/-", makeItem(3)]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2, 3])
  })

  it("inserts at 0 (prepend) places item at front", () => {
    const state: Record<string, unknown> = { items: [makeItem(2), makeItem(3)] }
    applyPatch(state, [["upsert", "/items/0", makeItem(1)]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2, 3])
  })

  it("updates item IN PLACE when __dom_id already exists — AC7", () => {
    const state: Record<string, unknown> = {
      items: [makeItem(1), makeItem(2), makeItem(3)],
    }
    const updated = makeItem(2, { name: "Updated Item 2" })
    applyPatch(state, [["upsert", "/items/-", updated]])
    const items = state.items as { id: number; name: string }[]
    // Length must not change — no duplication
    expect(items.length).toBe(3)
    // The item at its original position (index 1) is updated
    expect(items[1].name).toBe("Updated Item 2")
    expect(items[1].__dom_id).toBe("items-2")
  })

  it("upsert in-place preserves surrounding items unchanged", () => {
    const state: Record<string, unknown> = {
      items: [makeItem(1), makeItem(2), makeItem(3)],
    }
    applyPatch(state, [["upsert", "/items/0", makeItem(2, { name: "X" })]])
    const items = state.items as { id: number; name: string }[]
    expect(items.length).toBe(3)
    expect(items.find((i) => i.id === 2)?.name).toBe("X")
    expect(items.find((i) => i.id === 1)?.name).toBe("Item 1")
    expect(items.find((i) => i.id === 3)?.name).toBe("Item 3")
  })

  it("multiple upserts build list in correct append order", () => {
    const state: Record<string, unknown> = { items: [] }
    applyPatch(state, [
      ["replace", "/items", []],
      ["upsert", "/items/-", makeItem(1)],
      ["upsert", "/items/-", makeItem(2)],
      ["upsert", "/items/-", makeItem(3)],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2, 3])
  })

  it("multiple upserts at 0 produce reversed order", () => {
    const state: Record<string, unknown> = { items: [] }
    applyPatch(state, [
      ["replace", "/items", []],
      ["upsert", "/items/0", makeItem(1)],
      ["upsert", "/items/0", makeItem(2)],
      ["upsert", "/items/0", makeItem(3)],
    ])
    // Each prepended: [3, 2, 1]
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([3, 2, 1])
  })

  it("replace then upserts correctly resets and repopulates", () => {
    const state: Record<string, unknown> = { items: [makeItem(99)] }
    applyPatch(state, [
      ["replace", "/items", []],
      ["upsert", "/items/-", makeItem(1)],
      ["upsert", "/items/-", makeItem(2)],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2])
  })
})

// ---------------------------------------------------------------------------
// limit op
// ---------------------------------------------------------------------------

describe("limit op", () => {
  it("positive limit keeps first N items", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3), makeItem(4)] }
    applyPatch(state, [["limit", "/items", 2]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2])
  })

  it("negative limit keeps last N items", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3), makeItem(4)] }
    applyPatch(state, [["limit", "/items", -2]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([3, 4])
  })

  it("limit larger than array length is a no-op", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2)] }
    applyPatch(state, [["limit", "/items", 10]])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2])
  })

  it("limit 0 empties the array", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2)] }
    applyPatch(state, [["limit", "/items", 0]])
    expect(state.items).toEqual([])
  })

  it("upsert followed by limit maintains sliding window", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3)] }
    applyPatch(state, [
      ["upsert", "/items/-", makeItem(4)],
      ["limit", "/items", -3],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([2, 3, 4])
  })
})

// ---------------------------------------------------------------------------
// Stream patch sequence (full pipeline simulation)
// ---------------------------------------------------------------------------

describe("stream patch sequences (end-to-end simulation)", () => {
  it("initial render: replace then upserts populates state correctly", () => {
    const state: Record<string, unknown> = {}
    applyPatch(state, [
      ["replace", "/items", []],
      ["upsert", "/items/-", makeItem(1)],
      ["upsert", "/items/-", makeItem(2)],
      ["upsert", "/items/-", makeItem(3)],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2, 3])
  })

  it("delete via $$dom_id then insert leaves correct state", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3)] }
    applyPatch(state, [
      ["remove", "/items/$$items-2"],
      ["upsert", "/items/-", makeItem(4)],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 3, 4])
  })

  it("clear (replace []) removes all items", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3)] }
    applyPatch(state, [["replace", "/items", []]])
    expect(state.items).toEqual([])
  })

  it("reset with at:-1 restores items in append order", () => {
    const state: Record<string, unknown> = { items: [makeItem(1), makeItem(2), makeItem(3)] }
    applyPatch(state, [
      ["replace", "/items", []],
      ["upsert", "/items/-", makeItem(1)],
      ["upsert", "/items/-", makeItem(2)],
      ["upsert", "/items/-", makeItem(3)],
    ])
    expect((state.items as { id: number }[]).map((i) => i.id)).toEqual([1, 2, 3])
  })
})
