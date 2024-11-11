import {normalizeComponents} from "./utils"
import {render} from "svelte/server"
import {createRawSnippet} from "svelte"

export function getRender(components) {
    components = normalizeComponents(components)

    return function r(name, props, slots) {
        const snippets = Object.fromEntries(
            Object.entries(slots).map(([slotName, v]) => {
                const snippet = createRawSnippet(name => {
                    return {
                        render: () => v,
                    }
                })
                if (slotName === "default") return ["children", snippet]
                else return [slotName, snippet]
            })
        )

        return render(components[name], {props: {...props, ...snippets}})
    }
}
