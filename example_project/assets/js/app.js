// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {createLiveJsonHooks} from "live_json"
import {getHooks} from "live_svelte"
import * as Components from "../svelte/**/*.svelte"

function formatPayload(str) {
    if (!str || str === "—") return "—"
    try {
        return JSON.stringify(JSON.parse(str), null, 2)
    } catch {
        return str
    }
}

const PropsDiffPayloadDisplay = {
    mounted() {
        this.updateDisplays()
        const root = this.el
        const diffOnEl = root.querySelector("[data-name='PropsDiffDemo'][data-use-diff='true']")
        const diffOffEl = root.querySelector("[data-name='PropsDiffDemo'][data-use-diff='false']")
        const observer = new MutationObserver(() => this.updateDisplays())
        if (diffOnEl) observer.observe(diffOnEl, {attributes: true, attributeFilter: ["data-props"]})
        if (diffOffEl) observer.observe(diffOffEl, {attributes: true, attributeFilter: ["data-props"]})
        this._observer = observer
    },
    updated() {
        this.updateDisplays()
    },
    destroyed() {
        this._observer?.disconnect()
    },
    updateDisplays() {
        const root = this.el
        const diffOnEl = root.querySelector("[data-name='PropsDiffDemo'][data-use-diff='true']")
        const diffOffEl = root.querySelector("[data-name='PropsDiffDemo'][data-use-diff='false']")
        const preOn = root.querySelector("#payload-display-diff-on")
        const preOff = root.querySelector("#payload-display-diff-off")
        if (preOn) preOn.textContent = formatPayload(diffOnEl?.getAttribute("data-props") ?? "—")
        if (preOff) preOff.textContent = formatPayload(diffOffEl?.getAttribute("data-props") ?? "—")
    },
}

const Hooks = {
    ...createLiveJsonHooks(),
    ...getHooks(Components),
    PropsDiffPayloadDisplay,
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
