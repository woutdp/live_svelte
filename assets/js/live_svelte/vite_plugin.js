/// <reference types="vite/client" />

import { resolve, relative } from "node:path"
import { readdirSync, existsSync } from "node:fs"

const VIRTUAL_MODULE_ID = "virtual:live-svelte-components"
const RESOLVED_VIRTUAL_MODULE_ID = "\0" + VIRTUAL_MODULE_ID

/**
 * Returns the base directory from a glob pattern (everything before the first `*`),
 * with any trailing slash stripped.
 * @param {string} pattern - Glob pattern like `'./svelte/**\/*.svelte'`
 * @returns {string}
 */
export function getBaseDir(pattern) {
  const idx = pattern.indexOf("*")
  return idx === -1 ? pattern : pattern.slice(0, idx).replace(/\/$/, "")
}

/**
 * Derives the component name from an absolute file path relative to its base directory.
 * Strips the `.svelte` extension and normalizes backslashes to forward slashes.
 * @param {string} filePath - Absolute path to the `.svelte` file
 * @param {string} baseDir - Absolute base directory (resolved from pattern)
 * @returns {string} Component name, e.g. `'Counter'` or `'forms/ContactForm'`
 */
export function getComponentName(filePath, baseDir) {
  return relative(baseDir, filePath)
    .replace(/\.svelte$/, "")
    .replace(/\\/g, "/")
}

/**
 * Recursively walks a directory and collects `.svelte` file paths.
 * @param {string} dir - Absolute path to the directory
 * @param {string[]} [results=[]] - Accumulator array
 * @returns {string[]}
 */
function walkDir(dir, results = []) {
  if (!existsSync(dir)) return results
  try {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const full = resolve(dir, entry.name)
      if (entry.isDirectory()) walkDir(full, results)
      else if (entry.name.endsWith(".svelte")) results.push(full)
    }
  } catch {
    /* ignore permission errors */
  }
  return results
}

/**
 * Generates ESM virtual module source from a pre-built list of discovered files.
 * Pure function — no filesystem access. Exported for testability.
 * Uses JSON.stringify for all embedded string literals to safely handle paths
 * or component names that contain single quotes or other special characters.
 * @param {{ file: string, baseDir: string }[]} files
 * @returns {string} ESM source code string
 */
export function buildModuleCode(files) {
  if (files.length === 0) {
    return `export default {}\n`
  }

  const imports = files
    .map(({ file }, i) => `import __c${i} from ${JSON.stringify(file.replace(/\\/g, "/"))}`)
    .join("\n")

  const entries = files
    .map(({ file, baseDir }, i) => `  ${JSON.stringify(getComponentName(file, baseDir))}: __c${i}`)
    .join(",\n")

  return `${imports}\nexport default {\n${entries}\n}\n`
}

/**
 * Discovers all `.svelte` files for the given component path patterns and
 * delegates code generation to `buildModuleCode`.
 * @param {string[]} componentPaths - Glob patterns relative to Vite project root
 * @param {string} root - Absolute Vite project root directory
 * @returns {string} ESM source code string
 */
function generateVirtualModuleCode(componentPaths, root) {
  const allFiles = []
  for (const pattern of componentPaths) {
    const baseDir = resolve(root, getBaseDir(pattern))
    const files = walkDir(baseDir)
    for (const file of files) {
      allFiles.push({ file, baseDir })
    }
  }
  return buildModuleCode(allFiles)
}

/**
 * @typedef {Object} PluginOptions
 * @property {string} [path] - SSR render endpoint path (default: "/ssr_render")
 * @property {string} [entrypoint] - SSR entrypoint file (default: "./js/server.js")
 * @property {string | string[]} [components] - Glob pattern(s) for Svelte component
 *   auto-discovery via `virtual:live-svelte-components`.
 *   Patterns are relative to the Vite project root (where vite.config.js lives).
 *   Default: `['./svelte/**\/*.svelte']`
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
 * LiveSvelte Vite plugin for SSR, hot reload support, and component auto-discovery.
 *
 * NOTE: Unlike LiveVue, LiveSvelte's `render()` function returns a `{head, html, css}`
 * object (not a plain HTML string). This plugin serialises that result as JSON so the
 * Elixir `LiveSvelte.SSR.ViteJS` module can decode it with `Jason.decode!/1`.
 *
 * **Component auto-discovery**: Import `virtual:live-svelte-components` to get a
 * `Record<name, Component>` map of all discovered Svelte components. Pass the map
 * directly to `getHooks()` and `getRender()`.
 *
 * @param {PluginOptions} [opts]
 * @returns {import("vite").Plugin}
 */
function liveSveltePlugin(opts = {}) {
  const componentPaths = opts.components
    ? Array.isArray(opts.components)
      ? opts.components
      : [opts.components]
    : ["./svelte/**/*.svelte"]

  let root = process.cwd()

  /** @type {import("vite").ViteDevServer | null} */
  let viteServer = null

  function invalidateVirtualModule() {
    if (viteServer) {
      const mod = viteServer.moduleGraph.getModuleById(RESOLVED_VIRTUAL_MODULE_ID)
      if (mod) {
        viteServer.moduleGraph.invalidateModule(mod)
        viteServer.ws.send({ type: "full-reload" })
      }
    }
  }

  return {
    name: "live-svelte",

    configResolved(config) {
      root = config.root
    },

    resolveId(id) {
      if (id === VIRTUAL_MODULE_ID) {
        return RESOLVED_VIRTUAL_MODULE_ID
      }
    },

    load(id) {
      if (id === RESOLVED_VIRTUAL_MODULE_ID) {
        return generateVirtualModuleCode(componentPaths, root)
      }
    },

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
      viteServer = server

      process.stdin.on("close", () => process.exit(0))
      process.stdin.resume()

      // Watch component directories for new/deleted .svelte files so the
      // virtual:live-svelte-components module stays up to date.
      const baseDirs = componentPaths.map(p => resolve(root, getBaseDir(p)))
      for (const dir of baseDirs) {
        if (existsSync(dir)) server.watcher.add(dir)
      }

      server.watcher.on("add", filePath => {
        if (filePath.endsWith(".svelte") && baseDirs.some(dir => filePath.startsWith(dir))) {
          invalidateVirtualModule()
        }
      })
      server.watcher.on("unlink", filePath => {
        if (filePath.endsWith(".svelte") && baseDirs.some(dir => filePath.startsWith(dir))) {
          invalidateVirtualModule()
        }
      })

      const ssrPath = opts.path || "/ssr_render"
      const entrypoint = opts.entrypoint || "./js/server.js"
      server.middlewares.use(function liveSvelteMiddleware(req, res, next) {
        if (req.method == "POST" && req.url?.split("?", 1)[0] === ssrPath) {
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
