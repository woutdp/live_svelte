import * as Components from '../svelte/components/**/*'
import {detach, insert, noop} from 'svelte/internal'

let {default: modules, filenames} = Components

filenames = filenames
    .map(name => name.replace('../svelte/components/', ''))
    .map(name => name.replace('.svelte', ''))

const components = Object.assign({}, ...modules.map((m, index) => ({[filenames[index]]: m.default})))

function base64ToElement(base64) {
    let template = document.createElement('div')
    template.innerHTML = atob(base64).trim()
    return template
}

export const createSlots = (slots, el) => {
    function createSlot(content) {
        element = base64ToElement(content)
        let savedTarget, savedAnchor, savedElement
        return () => {
            return {
                update() {
                    detach(savedElement)
                    insert(savedTarget, element, savedAnchor)
                    savedElement = element
                },
                c: noop,
                m(target, anchor) {
                    savedTarget = target
                    savedAnchor = anchor
                    savedElement = element
                    insert(target, element, anchor);
                },
                d(detaching) {
                    if (detaching && element.innerHTML) {
                        detach(element);
                    }
                },
                l: noop,
            };
        }
    }

    const svelteSlots = {}

    for (const slotName in slots) {
        svelteSlots[slotName] = [createSlot(slots[slotName])];
    }

    return svelteSlots
}

function getProps(ref) {
    const dataProps = ref.el.getAttribute('data-props')
    const props = dataProps ? JSON.parse(dataProps) : {}

    return {
        ...props,
        pushEvent: (event, data, callback) => ref.pushEvent(event, data, callback),
        $$slots: createSlots({default: ref.el.getAttribute('data-slot-default')}, ref.el),
        $$scope: {}
    }
}

function findSlotCtx(component) {
    return component.$$.ctx.find(ctxElement => ctxElement.default)
}

const SvelteComponent = {
    mounted() {
        const componentName = this.el.getAttribute('data-name')
        if (!componentName) {
            throw new Error('Component name must be provided')
        }

        const Component = components[componentName]
        if (!Component) {
            throw new Error(`Unable to find ${componentName} component.`)
        }

        this._instance = new Component({
            target: this.el,
            props: getProps(this),
            hydrate: true
        })
    },

    updated() {
        this._instance.$set(getProps(this))
        findSlotCtx(this._instance).default[0]().update()
    },

    destroyed() {
        this._instance?.$destroy()
    }
}

export default {
    SvelteComponent
}
