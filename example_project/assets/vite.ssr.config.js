import { defineConfig } from "vite"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"
import { fileURLToPath } from "url"
import path from "path"

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    svelte(),
    liveSveltePlugin({ entrypoint: "./js/server.vite.js" }),
  ],
  resolve: {
    alias: {
      live_svelte: path.resolve(__dirname, "../../assets/js/live_svelte/index.ts"),
    },
  },
  ssr: {
    // Bundle all dependencies into the output file so it works as a standalone
    // Node.js module (mirrors the old esbuild `bundle: true` behavior).
    noExternal: true,
  },
  build: {
    ssr: "./js/server.vite.js",
    outDir: "../priv/svelte",
    rollupOptions: {
      output: {
        entryFileNames: "server.js",
        format: "es",
      },
    },
  },
})
