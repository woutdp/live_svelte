/***
 * Render a component with the name, props and slots provided.
 */
export function render(serverPath, name, props = {}, slots = null) {
    // remove from cache in non-production environments
    // so that we can see changes
    if (process.env.NODE_ENV !== "production" && require.resolve(serverPath) in require.cache) {
        delete require.cache[require.resolve(serverPath)]
    }

    const component = require(serverPath)[name].default
    const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v])) || {}

    return component.render(props, {$$slots, context: new Map()})
}
