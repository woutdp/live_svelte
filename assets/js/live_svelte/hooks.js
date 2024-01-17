import {normalizeComponents} from "./utils"

function getAttributeJson(ref, attributeName) {
    const data = ref.el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

function detach(node) {
    node.parentNode?.removeChild(node)
}

function insert(target, node, anchor) {
    target.insertBefore(node, anchor || null)
}

function noop() {}

function getSlots(ref) {
    const slots = {}

    for (const slotName in getAttributeJson(ref, "data-slots")) {
        const slot = () => {
            return {
                getElement() {
                    const base64 = getAttributeJson(ref, "data-slots")[slotName]
                    const element = document.createElement("div")
                    element.innerHTML = atob(base64).trim()
                    return element
                },
                update() {
                    detach(this.savedElement)
                    this.savedElement = this.getElement()
                    insert(this.savedTarget, this.savedElement, this.savedAnchor)
                },
                c: noop,
                m(target, anchor) {
                    this.savedTarget = target
                    this.savedAnchor = anchor
                    this.savedElement = this.getElement()
                    insert(this.savedTarget, this.savedElement, this.savedAnchor)
                },
                d(detaching) {
                    if (detaching) detach(this.savedElement)
                },
                l: noop,
            }
        }

        slots[slotName] = [slot]
    }

    return slots
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
        live: ref,
        $$slots: getSlots(ref),
        $$scope: {},
    }
}

function findSlotCtx(component) {
    // The default slot always exists if there's a slot set
    // even if no slot is set for the explicit default slot
    return component.$$.ctx.find(ctxElement => ctxElement?.default)
}

export function getHooks(components) {
    components = normalizeComponents(components)

    const SvelteHook = {
        mounted() {
            const componentName = this.el.getAttribute("data-name")
            if (!componentName) {
                throw new Error("Component name must be provided")
            }

            const Component = components[componentName]
            if (!Component) {
                throw new Error(`Unable to find ${componentName} component.`)
            }

            for (const liveJsonElement of Object.keys(getAttributeJson(this, "data-live-json"))) {
                window.addEventListener(`${liveJsonElement}_initialized`, event => this._instance.$set(getProps(this)), false)
                window.addEventListener(`${liveJsonElement}_patched`, event => this._instance.$set(getProps(this)), false)
            }

            this._instance = new Component({
                target: this.el,
                props: getProps(this),
                hydrate: this.el.hasAttribute("data-ssr"),
            })
        },

        updated() {
            // Set the props
            this._instance.$set(getProps(this))

            // Set the slots
            const slotCtx = findSlotCtx(this._instance)
            for (const key in slotCtx) {
                slotCtx[key][0]().update()
            }
        },

        destroyed() {
            this._instance.$destroy()
        },
    }

    return {
        SvelteHook,
    }
}
