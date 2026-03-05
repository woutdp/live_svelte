import { decodeB64ToUTF8, normalizeComponents } from "./utils"
import { mount, hydrate, unmount, createRawSnippet } from "svelte"
import { applyPatch } from "./jsonPatch.js"
import { LIVE_SYMBOL, CONNECTION_SYMBOL } from "./composables"

function getAttributeJson(ref, attributeName) {
  const data = ref.el.getAttribute(attributeName)
  return data ? JSON.parse(data) : {}
}

function getSlots(ref) {
  let snippets = {}

  for (const slotName in getAttributeJson(ref, "data-slots")) {
    const base64 = getAttributeJson(ref, "data-slots")[slotName]
    const element = document.createElement("div")
    element.innerHTML = decodeB64ToUTF8(base64).trim()

    const snippet = createRawSnippet((_name) => {
      return {
        render: () => element.outerHTML,
      }
    })

    if (slotName === "default") snippets["children"] = snippet
    else snippets[slotName] = snippet
  }

  return snippets
}

function getProps(ref) {
  return {
    ...getAttributeJson(ref, "data-props"),
    ...getSlots(ref),
    live: ref,
  }
}

/**
 * Read a diff attribute from the element and return the compressed ops array.
 * Compressed format: [[op, path, value?], ...] — passed directly to applyPatch.
 * @param {object} ref - The hook reference
 * @param {string} attributeName - The data attribute to read (e.g. "data-props-diff", "data-streams-diff")
 * @returns {Array} Array of compressed op arrays
 */
function getDiff(ref, attributeName) {
  const data = ref.el.getAttribute(attributeName)
  if (!data) return []
  try {
    const ops = JSON.parse(data)
    return Array.isArray(ops) ? ops : []
  } catch {
    return []
  }
}

function update_state(ref) {
  const useDiff = ref.el.getAttribute("data-use-diff") === "true"
  const state = ref._instance?.state

  if (useDiff && state) {
    const diff = getDiff(ref, "data-props-diff")
    if (diff.length > 0) {
      // Tier 2 + 3: Apply JSON Patch operations to state in-place.
      applyPatch(state, diff)
    } else {
      // Tier 1 fallback: Only changed props are in data-props; merge into existing state.
      const payload = getAttributeJson(ref, "data-props")
      for (const key in payload) {
        // Server sends removed keys as `null` (JSON) for Tier 1; treat as "unset"
        if (payload[key] === null) state[key] = undefined
        else state[key] = payload[key]
      }
    }
    // Always keep live ref and slots in sync
    const slots = getSlots(ref)
    for (const key in slots) state[key] = slots[key]
    state.live = ref
  } else if (state) {
    const newProps = getProps(ref)
    for (const key in newProps) {
      state[key] = newProps[key]
    }
  }

  // Always apply streams diff unconditionally — independent of data-use-diff
  if (state) {
    const streamsDiff = getDiff(ref, "data-streams-diff")
    if (streamsDiff.length > 0) {
      applyPatch(state, streamsDiff)
    }
  }
}

export function getHooks(components) {
  components = normalizeComponents(components)

  const SvelteHook = {
    mounted() {
      let state = $state(getProps(this))
      let connectionState = $state({ connected: true })

      const componentName = this.el.getAttribute("data-name")
      if (!componentName) throw new Error("Component name must be provided")

      const Component = components[componentName]
      if (!Component) throw new Error(`Unable to find ${componentName} component.`)

      // Mount into the inner phx-update="ignore" div so LiveView's DOM
      // patching won't destroy Svelte's rendered content on server updates.
      const target = this.el.querySelector("[data-svelte-target]")

      if (!this.el.hasAttribute("data-ssr")) {
        target.innerHTML = ""
      }

      const hydrateOrMount = this.el.hasAttribute("data-ssr") ? hydrate : mount

      this._instance = hydrateOrMount(Component, {
        target,
        props: state,
        context: new Map([[LIVE_SYMBOL, this], [CONNECTION_SYMBOL, connectionState]]),
      })
      this._instance.state = state
      this._instance.connectionState = connectionState

      // Apply initial stream items from data-streams-diff
      const initialStreamsDiff = getDiff(this, "data-streams-diff")
      if (initialStreamsDiff.length > 0) {
        applyPatch(state, initialStreamsDiff)
      }
    },

    updated() {
      update_state(this)
    },

    // Updates the reactive connection state shared via Svelte context with
    // useLiveConnection(). Unit-testing these is impractical (requires Svelte
    // $state outside a component context); correctness is validated by
    // the Chat.svelte `data-testid="chat-reconnecting"` E2E happy-path test
    // and by the Chat page remaining functional through connect/disconnect cycles.
    disconnected() {
      if (this._instance?.connectionState) {
        this._instance.connectionState.connected = false
      }
    },

    reconnected() {
      if (this._instance?.connectionState) {
        this._instance.connectionState.connected = true
      }
    },

    destroyed() {
      if (this._instance) window.addEventListener("phx:page-loading-stop", () => unmount(this._instance), { once: true })
    },
  }

  return {
    SvelteHook,
  }
}

