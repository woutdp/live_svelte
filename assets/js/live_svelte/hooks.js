import {detach, insert, noop} from "svelte/internal"
import {exportSvelteComponents} from "./utils"

function base64ToElement(base64) {
    let template = document.createElement("div")
    template.innerHTML = atob(base64).trim()
    return template
}

function dataAttributeToJson(attributeName, el) {
    const data = el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

function createSlots(slots, ref) {
    const createSlot = (slotName, ref) => {
        let savedTarget, savedAnchor, savedElement
        return () => {
            return {
                getElement() {
                    return base64ToElement(dataAttributeToJson("data-slots", ref.el)[slotName])
                },
                update() {
                    const element = this.getElement()
                    detach(savedElement)
                    insert(savedTarget, element, savedAnchor)
                    savedElement = element
                },
                c: noop,
                m(target, anchor) {
                    const element = this.getElement()
                    savedTarget = target
                    savedAnchor = anchor
                    savedElement = element
                    insert(target, element, anchor)
                },
                d(detaching) {
                    if (detaching) detach(savedElement)
                },
                l: noop,
            }
        }
    }

    const svelteSlots = {}

    for (const slotName in slots) {
        svelteSlots[slotName] = [createSlot(slotName, ref)]
    }

    return svelteSlots
}

function getLiveJsonProps(ref) {
    liveJsonData = {}
    for (const liveJsonElement of dataAttributeToJson("data-live-json", ref.el)) {
        if (window[liveJsonElement]) liveJsonData[liveJsonElement] = window[liveJsonElement]
    }
    return liveJsonData
}

function getProps(ref) {

    return {
        ...dataAttributeToJson("data-props", ref.el),
        ...getLiveJsonProps(ref),
        pushEvent: (event, data, callback) => ref.pushEvent(event, data, callback),
        pushEventTo: (selectorOrTarget, event, data, callback) => ref.pushEventTo(selectorOrTarget, event, data, callback),
        $$slots: createSlots(dataAttributeToJson("data-slots", ref.el), ref),
        $$scope: {},
    }
}

function findSlotCtx(component) {
    // The default slot always exists if there's a slot set
    // even if no slot is set for the explicit default slot
    return component.$$.ctx.find(ctxElement => ctxElement?.default)
}

export function getHooks(Components) {
    const components = exportSvelteComponents(Components)

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

            for (const liveJsonElement of dataAttributeToJson("data-live-json", this.el)) {
                window.addEventListener(`${liveJsonElement}_initialized`, event => this._instance.$set(getProps(this)), false)
                window.addEventListener(`${liveJsonElement}_patched`, event => this._instance.$set(getProps(this)), false)
            }

            this._instance = new Component({
                target: this.el,
                props: getProps(this),
                hydrate: true,
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
            // We don't want to destroy the component
            // If we do a page navigation, this would remove the component in the DOM,
            // and then it would to the transition, causing a flicker of unrendered content
            // Since we're doing a page transition anyway, the component will be remove automatically
        },
    }

    return {
        SvelteHook,
    }
}
