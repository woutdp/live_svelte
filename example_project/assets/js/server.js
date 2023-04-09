import * as Components from "../svelte/**/*"
import {exportSvelteComponents, render} from "live_svelte"

module.exports = exportSvelteComponents(Components)
module.exports.ssrRenderComponent = render
