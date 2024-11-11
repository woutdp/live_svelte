import {normalizeComponents} from "./utils"
import {mount, hydrate, unmount, createRawSnippet} from "svelte"

function getAttributeJson(ref, attributeName) {
    const data = ref.el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

function getSlots(ref) {
    let snippets = {}

    for (const slotName in getAttributeJson(ref, "data-slots")) {
        const base64 = getAttributeJson(ref, "data-slots")[slotName]
        const element = document.createElement("div")
        element.innerHTML = atob(base64).trim()

        const snippet = createRawSnippet(name => {
            return {
                render: () => element.outerHTML,
            }
        })

        if (slotName === "default") snippets["children"] = snippet
        else snippets[slotName] = snippet
    }

    return snippets
}

function getLiveJsonProps(ref) {
    const json = getAttributeJson(ref, "data-live-json")

    // On SSR, data-live-json is the full object we want
    // After SSR, data-live-json is an array of keys, and we'll get the data from the window
    if (!Array.isArray(json)) return json

    const liveJsonData = {}
    for (const liveJsonVariable of json) {
        const data = window[liveJsonVariable]
        if (data) liveJsonData[liveJsonVariable] = data
    }
    return liveJsonData
}

function getProps(ref) {
    return {
        ...getAttributeJson(ref, "data-props"),
        ...getLiveJsonProps(ref),
        ...getSlots(ref),
        live: ref,
    }
}

function findSlotCtx(component) {
    // The default slot always exists if there's a slot set
    // even if no slot is set for the explicit default slot
    return component.$$.ctx.find(ctxElement => ctxElement?.default)
}

function update_state(ref) {
    const newProps = getProps(ref)
    for (const key in newProps) {
        ref._instance.state[key] = newProps[key]
    }
}

export function getHooks(components) {
    components = normalizeComponents(components)

    const SvelteHook = {
        mounted() {
            let state = $state(getProps(this))
            const componentName = this.el.getAttribute("data-name")
            if (!componentName) throw new Error("Component name must be provided")

            const Component = components[componentName]
            if (!Component) throw new Error(`Unable to find ${componentName} component.`)

            for (const liveJsonElement of Object.keys(getAttributeJson(this, "data-live-json"))) {
                window.addEventListener(`${liveJsonElement}_initialized`, _event => update_state(this), false)
                window.addEventListener(`${liveJsonElement}_patched`, _event => update_state(this), false)
            }

            const hydrateOrMount = this.el.hasAttribute("data-ssr") ? hydrate : mount

            this._instance = hydrateOrMount(Component, {
                target: this.el,
                props: state,
            })
            this._instance.state = state
        },

        updated() {
            update_state(this)
        },

        destroyed() {
            if (this._instance) window.addEventListener("phx:page-loading-stop", () => unmount(this._instance), {once: true})
        },
    }

    return {
        SvelteHook,
    }
}
