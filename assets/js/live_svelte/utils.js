export function normalizeComponents(components) {
    if (!Array.isArray(components.default) || !Array.isArray(components.filenames)) return components

    const normalized = {}
    for (const [index, module] of components.default.entries()) {
        const Component = module.default
        const name = components.filenames[index].replace("../svelte/", "").replace(".svelte", "")
        normalized[name] = Component
    }
    return normalized
}
