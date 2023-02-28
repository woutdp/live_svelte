module.exports.render = (name, props={}, slots=null) => {
    const ssrComponent = require('../../priv/static/assets/server/server.js')[name].default
    const $$slots = slots ? {default: () => slots} : {}
    return ssrComponent.render(props, {$$slots, context: new Map()})
}
