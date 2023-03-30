export function exportSvelteComponents(components) {
    let {default: modules, filenames} = components

    filenames = filenames.map(name => name.replace("../svelte/", "")).map(name => name.replace(".svelte", ""))

    return Object.assign({}, ...modules.map((m, index) => ({[filenames[index]]: m.default})))
}
