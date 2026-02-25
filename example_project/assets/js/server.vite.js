// Vite SSR entry point for liveSveltePlugin's /ssr_render endpoint.
// Uses Vite-native import.meta.glob instead of the esbuild-plugin-import-glob
// syntax used by server.js. Configured via vite.config.js:
//   liveSveltePlugin({ entrypoint: './js/server.vite.js' })
import { getRender } from "live_svelte"

// import.meta.glob returns Record<path, module> (e.g. {"../svelte/Counter.svelte": {default: ...}}).
// getRender/getHooks expect Record<name, Component> (e.g. {"Counter": Component}).
// Transform: strip path prefix and .svelte extension to get the component name.
const rawComponents = import.meta.glob("../svelte/**/*.svelte", { eager: true })
const Components = Object.fromEntries(
  Object.entries(rawComponents).map(([path, mod]) => [
    path.replace("../svelte/", "").replace(".svelte", ""),
    mod.default,
  ])
)

export const render = getRender(Components)
