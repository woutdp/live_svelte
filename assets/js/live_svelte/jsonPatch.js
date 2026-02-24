/**
 * Minimal JSON Patch (RFC 6902) implementation for LiveSvelte.
 * Applies compressed patch operations [op, path, value?] to a state object in-place,
 * preserving Svelte 5 $state() reactivity via proxy mutations.
 */

function unescapePath(path) {
  return path.replace(/~1/g, "/").replace(/~0/g, "~")
}

function resolveKey(key, obj) {
  const unescaped = key.includes("~") ? unescapePath(key) : key
  if (Array.isArray(obj)) {
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
    obj = obj[resolveKey(key, obj)]
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
    obj = obj[resolveKey(keys[i], obj)]
    if (obj == null) return doc
  }

  const finalKey = resolveKey(keys[keys.length - 1], obj)

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
