// SSR entry point for LiveSvelte (used by --ssr js/server.js).
import { getRender } from "live_svelte"
import Components from "virtual:live-svelte-components"

export const render = getRender(Components)
