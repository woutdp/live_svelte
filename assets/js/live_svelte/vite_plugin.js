/// <reference types="vite/client" />

/**
 * @typedef {Object} PluginOptions
 * @property {string} [path] - SSR render endpoint path (default: "/ssr_render")
 * @property {string} [entrypoint] - SSR entrypoint file (default: "./js/server.js")
 */

/**
 * @param {string} path
 * @returns {"css-update" | "js-update" | null}
 */
function hotUpdateType(path) {
  if (path.endsWith("css")) return "css-update"
  if (path.endsWith("js")) return "js-update"
  return null
}

/**
 * @param {import("http").ServerResponse} res
 * @param {number} statusCode
 * @param {unknown} data
 */
const jsonResponse = (res, statusCode, data) => {
  res.statusCode = statusCode
  res.setHeader("Content-Type", "application/json")
  res.end(JSON.stringify(data))
}

/**
 * Custom JSON parsing middleware
 * @param {import("http").IncomingMessage & { body?: Record<string, unknown> }} req
 * @param {import("http").ServerResponse} res
 * @param {() => Promise<void>} next
 */
const jsonMiddleware = (req, res, next) => {
  let data = ""

  req.on("data", chunk => {
    data += chunk
  })

  req.on("end", () => {
    try {
      req.body = JSON.parse(data)
      next()
    } catch (error) {
      jsonResponse(res, 400, { error: "Invalid JSON" })
    }
  })

  req.on("error", err => {
    console.error(err)
    jsonResponse(res, 500, { error: "Internal Server Error" })
  })
}

/**
 * LiveSvelte Vite plugin for SSR and hot reload support.
 *
 * NOTE: Unlike LiveVue, LiveSvelte's `render()` function returns a `{head, html, css}`
 * object (not a plain HTML string). This plugin serialises that result as JSON so the
 * Elixir `LiveSvelte.SSR.ViteJS` module can decode it with `Jason.decode!/1`.
 *
 * @param {PluginOptions} [opts]
 * @returns {import("vite").Plugin}
 */
function liveSveltePlugin(opts = {}) {
  return {
    name: "live-svelte",
    handleHotUpdate({ file, modules, server, timestamp }) {
      if (file.match(/\.(heex|ex)$/)) {
        const invalidatedModules = new Set()
        for (const mod of modules) {
          server.moduleGraph.invalidateModule(mod, invalidatedModules, timestamp, true)
        }

        const updates = Array.from(invalidatedModules).flatMap(m => {
          const { file } = m

          if (!file) return []

          const updateType = hotUpdateType(file)

          if (!updateType) return []

          return {
            type: updateType,
            path: m.url,
            acceptedPath: m.url,
            timestamp: timestamp,
          }
        })

        server.ws.send({
          type: "update",
          updates,
        })

        return []
      }
    },
    configureServer(server) {
      process.stdin.on("close", () => process.exit(0))
      process.stdin.resume()

      const path = opts.path || "/ssr_render"
      const entrypoint = opts.entrypoint || "./js/server.js"
      server.middlewares.use(function liveSvelteMiddleware(req, res, next) {
        if (req.method == "POST" && req.url?.split("?", 1)[0] === path) {
          jsonMiddleware(req, res, async () => {
            try {
              const render = (await server.ssrLoadModule(entrypoint)).render
              const result = await render(req.body?.name, req.body?.props, req.body?.slots)
              // LiveSvelte render returns {head, html, css} — must JSON-encode for Elixir decoder
              res.setHeader("Content-Type", "application/json")
              res.end(JSON.stringify(result))
            } catch (e) {
              e instanceof Error && server.ssrFixStacktrace(e)
              jsonResponse(res, 500, { error: e })
            }
          })
        } else {
          next()
        }
      })
    },
  }
}

export default liveSveltePlugin
