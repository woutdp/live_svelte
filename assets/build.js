const esbuild = require("esbuild")
const sveltePlugin = require("esbuild-svelte")
const args = process.argv.slice(2)
const watch = args.includes("--watch")
const deploy = args.includes("--deploy")

let moduleOpts = {
    entryPoints: ["js/live_svelte/index.js"],
    bundle: true,
    format: "esm",
    outfile: "../priv/static/live_svelte.esm.js",
    external: ["svelte"],
    logLevel: "info",
    sourcemap: true,
    plugins: [sveltePlugin({})],
}

let mainOpts = {
    entryPoints: ["js/live_svelte/index.js"],
    bundle: true,
    conditions: ["svelte", "browser"],
    format: "cjs",
    outfile: "../priv/static/live_svelte.cjs.js",
    logLevel: "info",
    external: ["svelte"],
    sourcemap: true,
    plugins: [sveltePlugin({})],
}

let cdnOpts = {
    entryPoints: ["js/live_svelte/index.js"],
    bundle: true,
    target: "es2016",
    format: "iife",
    globalName: "LiveSvelte",
    outfile: "../priv/static/live_svelte.js",
    logLevel: "info",
    plugins: [sveltePlugin({})],
}

let cdnMinOpts = {
    entryPoints: ["js/live_svelte/index.js"],
    bundle: true,
    minify: true,
    target: "es2016",
    format: "iife",
    globalName: "LiveSvelte",
    outfile: "../priv/static/live_svelte.min.js",
    logLevel: "info",
    plugins: [sveltePlugin({})],
}

if (watch) {
    esbuild
        .context(moduleOpts)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
    esbuild
        .context(mainOpts)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
    esbuild
        .context(cdnOpts)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
    esbuild
        .context(cdnMinOpts)
        .then(ctx => ctx.watch())
        .catch(_error => process.exit(1))
} else {
    esbuild.build(moduleOpts)
    esbuild.build(mainOpts)
    esbuild.build(cdnOpts)
    esbuild.build(cdnMinOpts)
}
