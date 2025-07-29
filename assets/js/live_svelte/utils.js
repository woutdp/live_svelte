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

export function decodeB64ToUTF8(b64) {
    const chars = Uint8Array.from(atob(b64), c => c.charCodeAt(0))
    return new TextDecoder().decode(chars)
}
