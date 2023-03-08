module.exports.render = (name, props={}, slots=null) => {
    const ssrComponent = require('../../priv/static/assets/server/server.js')[name].default
    slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v]))
    const $$slots = slots || {}
    return ssrComponent.render(props, {$$slots, context: new Map()})
}
