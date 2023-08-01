import {normalizeComponents} from "./utils"

export function getRender(components) {
    components = normalizeComponents(components)

    return function render(name, props, slots) {
        const Component = components[name]
        const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v]))
        return Component.render(props, {$$slots})
    }
}
