// Vite SSR entry point for liveSveltePlugin's /ssr_render endpoint.
// Uses Vite-native import.meta.glob instead of the esbuild-plugin-import-glob
// syntax used by server.js. Configured via vite.config.js:
//   liveSveltePlugin({ entrypoint: './js/server.vite.js' })
import { getRender } from "live_svelte"

const Components = import.meta.glob("../svelte/**/*.svelte", { eager: true })

export const render = getRender(Components)
