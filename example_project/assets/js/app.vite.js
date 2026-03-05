// Client-side entry point for both Vite dev server (HMR) and production builds.
// Uses virtual:live-svelte-components (provided by liveSveltePlugin) instead of
// the esbuild-plugin-import-glob glob syntax used by the old esbuild app.js entry.

import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
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
