/**
 * Minimal JSON Patch (RFC 6902) implementation for LiveSvelte.
 * Applies compressed patch operations [op, path, value?] to a state object in-place,
 * preserving Svelte 5 $state() reactivity via proxy mutations.
 */

function unescapePath(path) {
  return path.replace(/~1/g, "/").replace(/~0/g, "~")
}

/**
 * Resolve a path component, supporting special $$<dom_id> syntax for stream arrays.
 * If the component starts with $$, finds the array index where item.__dom_id matches.
 * Returns the numeric index (for arrays) or string key (for objects).
 */
function resolveKey(key, obj) {
  const unescaped = key.includes("~") ? unescapePath(key) : key
  if (Array.isArray(obj)) {
    if (unescaped.startsWith("$$")) {
      const targetId = unescaped.substring(2)
      const index = obj.findIndex(
        (item) => item && typeof item === "object" && item.__dom_id == targetId
      )
      if (index === -1) {
        console.warn(`JSON Patch: item with __dom_id "${targetId}" not found, skipping`)
        return null
      }
      return index
    }
    return unescaped === "-" ? obj.length : parseInt(unescaped, 10)
  }
  return unescaped
}

function getByPointer(doc, pointer) {
  if (!pointer) return doc
  const keys = pointer.split("/").slice(1)
  let obj = doc
  for (const key of keys) {
    if (obj == null) return undefined
    const resolved = resolveKey(key, obj)
    if (resolved === null) return undefined
    obj = obj[resolved]
  }
  return obj
}

function applyOperation(doc, operation) {
  if (operation.path === "") {
    if (operation.op === "add" || operation.op === "replace") return operation.value
    if (operation.op === "remove") return null
    return doc
  }

  const keys = operation.path.split("/").slice(1)
  let obj = doc

  for (let i = 0; i < keys.length - 1; i++) {
    const resolved = resolveKey(keys[i], obj)
    if (resolved === null) return doc // $$dom_id not found, skip op
    obj = obj[resolved]
    if (obj == null) return doc
  }

  const finalKey = resolveKey(keys[keys.length - 1], obj)
  if (finalKey === null) return doc // $$dom_id not found, skip op

  if (Array.isArray(obj)) {
    const index = typeof finalKey === "number" ? finalKey : parseInt(finalKey, 10)
    switch (operation.op) {
      case "add":
        obj.splice(index, 0, operation.value)
        break
      case "remove":
        obj.splice(index, 1)
        break
      case "replace":
        obj[index] = operation.value
        break
      case "upsert": {
        const upsertValue = operation.value
        if (upsertValue && typeof upsertValue === "object" && "__dom_id" in upsertValue) {
          const existingIndex = obj.findIndex(
            (item) => item && typeof item === "object" && item.__dom_id === upsertValue.__dom_id
          )
          if (existingIndex !== -1) {
            obj[existingIndex] = upsertValue
          } else {
            obj.splice(index, 0, upsertValue)
          }
        } else {
          obj.splice(index, 0, upsertValue)
        }
        break
      }
      case "limit": {
        const limitValue = operation.value
        if (typeof limitValue === "number") {
          if (limitValue >= 0) {
            if (limitValue < obj.length) obj.splice(limitValue)
          } else {
            const keepCount = Math.abs(limitValue)
            if (keepCount < obj.length) obj.splice(0, obj.length - keepCount)
          }
        }
        break
      }
      case "move": {
        const val = getByPointer(doc, operation.from)
        applyOperation(doc, { op: "remove", path: operation.from })
        obj.splice(index, 0, val)
        break
      }
      case "copy": {
        const val = getByPointer(doc, operation.from)
        obj.splice(index, 0, JSON.parse(JSON.stringify(val)))
        break
      }
    }
  } else {
    switch (operation.op) {
      case "add":
      case "replace":
        obj[finalKey] = operation.value
        break
      case "remove":
        delete obj[finalKey]
        break
      case "limit": {
        // limit on an object key that holds an array
        const targetArray = obj[finalKey]
        if (Array.isArray(targetArray)) {
          const limitValue = operation.value
          if (typeof limitValue === "number") {
            if (limitValue >= 0) {
              if (limitValue < targetArray.length) targetArray.splice(limitValue)
            } else {
              const keepCount = Math.abs(limitValue)
              if (keepCount < targetArray.length) targetArray.splice(0, targetArray.length - keepCount)
            }
          }
        }
        break
      }
      case "move": {
        const val = getByPointer(doc, operation.from)
        applyOperation(doc, { op: "remove", path: operation.from })
        obj[finalKey] = val
        break
      }
      case "copy": {
        const val = getByPointer(doc, operation.from)
        obj[finalKey] = JSON.parse(JSON.stringify(val))
        break
      }
    }
  }

  return doc
}

/**
 * Convert a compressed [op, path, value?] array to an operation object.
 * For "move" and "copy", the third element is the "from" path.
 */
function compressedToOp([op, path, value]) {
  const operation = { op, path }
  if (value !== undefined) {
    if (op === "move" || op === "copy") operation.from = value
    else operation.value = value
  }
  return operation
}

/**
 * Apply an array of compressed JSON Patch operations to a state object in-place.
 * Skips "test" operations (used only for cache-busting).
 *
 * @param {object} state - The state object to mutate (Svelte $state() proxy)
 * @param {Array} ops - Array of compressed ops: [[op, path, value?], ...]
 * @returns {object} The mutated state
 */
export function applyPatch(state, ops) {
  if (!ops || ops.length === 0) return state
  for (const compressed of ops) {
    if (compressed[0] === "test") continue
    applyOperation(state, compressedToOp(compressed))
  }
  return state
}
