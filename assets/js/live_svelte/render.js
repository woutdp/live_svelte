import {render} from "svelte/server"
import {normalizeComponents} from "./utils"

export function getRender(components) {
    components = normalizeComponents(components)

    return (name, props, slots) => {
        const Component = components[name]
        const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v]))
        return render(Component, props, {props: {$$slots}})
    }
}
