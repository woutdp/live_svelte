const path = require("path")
const serverPath = path.resolve("./priv/static/assets/server/server.js")

module.exports.render = require("live_svelte").getRender(serverPath)
