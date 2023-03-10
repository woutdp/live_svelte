const componentPath = '../../priv/static/assets/server/server.js'

/***
 * Render a component with the name, props and slots provided.
 */
function render(name, props = {}, slots = null) {
    // remove from cache in non-production environments
    // so that we can see changes
    if (
        process.env.NODE_ENV !== 'production' &&
        require.resolve(componentPath) in require.cache
    ) {
        delete require.cache[require.resolve(componentPath)]
    }

    const component = require(componentPath)[name].default
    const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v])) || {}

    return component.render(props, { $$slots, context: new Map() })
}

module.exports = {
    render,
}
