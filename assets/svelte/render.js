var path = require("path")
var absolutePath = path.resolve("./priv/static/assets/server/server.js")

module.exports.render = require("live_svelte").getRender(absolutePath)
