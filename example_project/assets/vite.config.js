import { defineConfig } from "vite"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"

export default defineConfig({
  plugins: [svelte(), liveSveltePlugin({ entrypoint: "./js/server.vite.js" })],
  server: {
    host: "localhost",
    port: 5173,
  },
})
