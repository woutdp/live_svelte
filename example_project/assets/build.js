const esbuild = require("esbuild")
const sveltePlugin = require("esbuild-svelte")
const importGlobPlugin = require("esbuild-plugin-import-glob").default
const sveltePreprocess = require("svelte-preprocess")
const path = require("path")

const assetsDir = __dirname
const liveSvelteRoot = path.resolve(assetsDir, "../..")
const depsDir = path.resolve(assetsDir, "../deps")

const args = process.argv.slice(2)
const watch = args.includes("--watch")
const deploy = args.includes("--deploy")

let clientConditions = ["svelte", "browser"]
let serverConditions = ["svelte"]

if (!deploy) {
    clientConditions.push("development")
    serverConditions.push("development")
}

let optsClient = {
    entryPoints: ["js/app.js"],
    bundle: true,
    minify: deploy,
    platform: "browser",
    conditions: clientConditions,
    external: ["node:crypto", "node:async_hooks"],
    alias: {
        live_svelte: liveSvelteRoot,
        $lib: path.resolve(assetsDir, "svelte"),
        svelte: "svelte",
    },
    outdir: "../priv/static/assets/js",
    logLevel: "debug",
    sourcemap: watch ? "inline" : false,
    tsconfig: "./tsconfig.json",
    plugins: [
        importGlobPlugin(),
        sveltePlugin({
            preprocess: sveltePreprocess(),
            compilerOptions: {dev: !deploy, css: "injected", generate: "client"},
        }),
    ],
}

let optsServer = {
    entryPoints: ["js/server.js"],
    platform: "node",
    bundle: true,
    minify: false,
    target: "node19.6.1",
    conditions: serverConditions,
    alias: {
        live_svelte: liveSvelteRoot,
        $lib: path.resolve(assetsDir, "svelte"),
        svelte: "svelte",
    },
    outdir: "../priv/svelte",
    logLevel: "debug",
    sourcemap: watch ? "inline" : false,
    tsconfig: "./tsconfig.json",
    plugins: [
        importGlobPlugin(),
        sveltePlugin({
            preprocess: sveltePreprocess(),
            compilerOptions: {dev: !deploy, css: "injected", generate: "server"},
        }),
    ],
}

if (watch) {
    esbuild
        .context(optsClient)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
    esbuild
        .context(optsServer)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
} else {
    esbuild.build(optsClient)
    esbuild.build(optsServer)
}
