module.exports.render = (name, props={}) => {
    const ssrComponent = require('../../priv/static/assets/server/server.js')[name].default
    return ssrComponent.render(props)
}