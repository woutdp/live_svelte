// Client-side entry point for both Vite dev server (HMR) and production builds.
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "topbar"
import {getHooks} from "live_svelte"
import Components from "virtual:live-svelte-components"

function normalizePathname(pathname) {
    if (!pathname) return "/"
    const p = pathname.trim()
    if (p.length > 1 && p.endsWith("/")) return p.slice(0, -1)
    return p
}

function enhanceNav(root = document) {
    const current = normalizePathname(window.location.pathname)

    // Active link highlighting (works for LiveView patches too).
    root.querySelectorAll("[data-nav-link]").forEach((a) => {
        const href = a.getAttribute("href")
        if (!href || !href.startsWith("/")) return
        const target = normalizePathname(href)
        if (target === current) a.setAttribute("aria-current", "page")
        else a.removeAttribute("aria-current")
    })

    // Drawer quick filter
    const filter = root.querySelector("[data-nav-filter]")
    const listRoot = root.querySelector("[data-nav-list]") ?? root
    if (!filter || filter.dataset.bound === "true") return
    filter.dataset.bound = "true"

    const run = () => {
        const q = (filter.value ?? "").trim().toLowerCase()
        const items = listRoot.querySelectorAll("[data-nav-item]")
        items.forEach((li) => {
            const t = (li.textContent ?? "").trim().toLowerCase()
            li.style.display = q === "" || t.includes(q) ? "" : "none"
        })

        listRoot.querySelectorAll("[data-nav-group]").forEach((group) => {
            const visible = Array.from(group.querySelectorAll("[data-nav-item]")).some(
                (li) => li.style.display !== "none"
            )
            group.style.display = visible ? "" : "none"
        })
    }

    filter.addEventListener("input", run, {passive: true})
}

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

topbar.config({barColors: {0: "#ff5c1a"}, shadowColor: "rgba(255, 92, 26, 0.25)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket

// Re-apply active link + filter binding on LV navigation.
window.addEventListener("phx:page-loading-stop", () => enhanceNav(document))
window.addEventListener("DOMContentLoaded", () => enhanceNav(document))
