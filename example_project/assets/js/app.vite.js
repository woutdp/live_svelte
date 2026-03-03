// Vite dev server entry point for HMR development.
// Replaces the esbuild-plugin-import-glob syntax in app.js with Vite's native
// import.meta.glob. The esbuild build (app.js) remains unchanged for production.

import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
// TODO(Epic 9): remove createLiveJsonHooks once live_json dependency is removed
import {createLiveJsonHooks} from "live_json"
import {getHooks} from "live_svelte"
import Components from "virtual:live-svelte-components"

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

topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket
