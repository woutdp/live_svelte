import { defineConfig } from "vite"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"
import { fileURLToPath } from "url"
import path from "path"

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    svelte({ compilerOptions: { css: "injected" } }),
    liveSveltePlugin({ entrypoint: "./js/server.vite.js" }),
  ],
  resolve: {
    // Explicit alias so Vite always resolves live_svelte to library TypeScript
    // source, regardless of package.json export condition availability.
    alias: {
      live_svelte: path.resolve(__dirname, "../../assets/js/live_svelte/index.ts"),
    },
  },
  build: {
    commonjsOptions: { include: [/vendor\//, /node_modules\//] },
    target: "es2020",
    outDir: "../priv/static/assets",
    emptyOutDir: true,
    sourcemap: false,
    manifest: false,
    rollupOptions: {
      input: {
        app: path.resolve(__dirname, "./js/app.vite.js"),
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "[name].js",
        assetFileNames: "[name][extname]",
      },
    },
  },
  server: {
    host: "localhost",
    port: 5173,
  },
})
