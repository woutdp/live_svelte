# Troubleshooting

Common issues encountered when using LiveSvelte, and how to resolve them.

## "My JS Changes Have No Effect"

**Symptom:** You modified a Svelte component or JavaScript file, but the browser still shows old behavior.

**Cause:** Vite hasn't rebuilt the assets, so the browser is loading stale bundles.

**Fix:**
```bash
cd example_project
mix assets.build && mix compile
```

`mix assets.build` runs Vite builds (client + SSR). `mix compile` copies the updated SSR bundle into `_build/`. Both steps are required after any change to `assets/`.

## SSR Renders Stale HTML

**Symptom:** Server-side rendered HTML shows old component output even after updating Svelte files.

**Cause:** `_build/test/lib/example/priv/svelte/server.js` is a **copy** (not a symlink) of `priv/svelte/server.js`. It is updated by `mix compile`, not by `mix assets.build` alone.

**Fix:**
```bash
mix assets.build && mix compile
```

If you're seeing stale SSR in tests, ensure the `on_exit` cleanup properly resets SSR state.

## Svelte CSS Overwrites Tailwind's `app.css`

**Symptom:** After building, `priv/static/assets/app.css` contains only Svelte component styles, and Tailwind styles are missing.

**Cause:** The Svelte Vite plugin is extracting component CSS to a file, which overwrites the Tailwind output.

**Fix:** Ensure your `vite.config.mjs` passes `css: "injected"` to the Svelte plugin:

```js
import { svelte } from "@sveltejs/vite-plugin-svelte"

export default defineConfig({
  plugins: [
    svelte({
      compilerOptions: {
        css: "injected"  // ← This is required
      }
    }),
    // ...
  ]
})
```

This injects Svelte component CSS directly into the JS bundle instead of extracting it to a separate file.

## Component Not Found / `virtual:live-svelte-components` Resolution Fails

**Symptom:** Browser console shows `Error: Failed to resolve module 'virtual:live-svelte-components'` or a specific component name is not found.

**Cause:** The `liveSveltePlugin` is missing from one or both Vite configs.

**Fix:** Ensure `liveSveltePlugin()` is in `vite.config.mjs` and that `ssr: { noExternal: ... }` is set. The same config is used for both client and SSR builds (via `phoenix_vite.npm vite build --ssr js/server.js ...`).

```js
// assets/vite.config.mjs
import liveSveltePlugin from "live_svelte/vitePlugin"
plugins: [svelte(), liveSveltePlugin({ entrypoint: "./js/server.js" })],
ssr: { noExternal: process.env.NODE_ENV === "production" ? true : undefined },
```

Also verify that your Svelte files are in `assets/svelte/` and have the `.svelte` extension.

## Unknown component: MyComponent (NodeJS SSR)

**Symptom:** `(NodeJS.Error) Unknown component: MyComponent` when using a newly added Svelte component in LiveView (e.g. after creating `assets/svelte/MyComponent.svelte` and using `<.svelte name="MyComponent" ...>`).

**Cause:** When using NodeJS SSR, the component registry is baked into `priv/svelte/server.js` at build time. New `.svelte` files are not included until you rebuild the SSR bundle.

**Fix (choose one):**

1. **Development (recommended):** Use ViteJS for SSR so new components are discovered automatically. In `config/dev.exs` add:
   ```elixir
   config :live_svelte, ssr_module: LiveSvelte.SSR.ViteJS, vite_host: "http://localhost:5173"
   ```
   Restart the server and ensure the Vite dev server is running (e.g. via the `:vite` watcher when you run `mix phx.server`). The Igniter installer (`mix igniter.install live_svelte`) adds this for you.

2. **After adding components when using NodeJS:** Rebuild the SSR bundle so the new component is included:
   ```bash
   mix assets.build
   ```

## Wallaby E2E Tests Fail

**Symptom:** Wallaby tests fail with a browser connection error or chromedriver not found.

**Cause:** chromedriver is not installed or not in `PATH`.

**Fix:**
```bash
# Check installation
chromedriver --version

# Install on macOS
brew install chromedriver

# Install on Ubuntu/Debian
sudo apt-get install chromium-driver

# Or use a specific version with webdriver-manager
npm install -g webdriver-manager
webdriver-manager update
```

Also ensure `mix assets.build` has been run before E2E tests — the browser needs the built JS to function.

## `mix live_svelte.install` Says "Task Not Found"

**Symptom:** Running `mix live_svelte.install` prints "The task 'live_svelte.install' could not be found".

**Cause:** The `:igniter` dependency is not in your project's deps, or `mix deps.get` hasn't been run.

**Fix:**
```bash
# Ensure igniter is installed
mix archive.install hex igniter_new

# Then install using igniter:
mix igniter.install live_svelte
```

If you added `{:live_svelte, ...}` to `mix.exs` and ran `mix deps.get` manually, also run:
```bash
mix deps.compile
```

## `import LiveSvelte` Missing from html_helpers

**Symptom:** Using `<.svelte>` in a LiveView template produces `function component svelte/1 is undefined`.

**Cause:** `import LiveSvelte` was not added to the web module's `html_helpers`.

**Fix:** Add it manually in `lib/my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    # ... existing imports ...
    import LiveSvelte
  end
end
```

> Note: use `import LiveSvelte`, not `use LiveSvelte`.

## Props Not Reactive After Navigation

**Symptom:** After navigating within the same LiveView, Svelte component props stop updating.

**Cause:** If `phx-update="ignore"` is missing or incorrectly overridden on the component wrapper, LiveView will re-patch Svelte's DOM on updates, breaking reactivity.

**Fix:** Do not add `phx-update` attributes to the `<.svelte>` component call — LiveSvelte sets it automatically on the wrapper div. If you are nesting the component inside a container with `phx-update`, ensure that container is set correctly:

```heex
<!-- ✅ Correct — let LiveSvelte manage its own wrapper -->
<.svelte name="Counter" props={%{count: @count}} socket={@socket} />

<!-- ❌ Wrong — wrapping in a plain div that LiveView re-renders -->
<div>
  <.svelte name="Counter" props={%{count: @count}} socket={@socket} />
</div>
```

For containers that wrap multiple components, use `phx-update="ignore"` on the outer container if it should not be re-rendered, or ensure each component has a stable `id`.

## NodeJS.Supervisor Not Starting

**Symptom:** Application fails to start with `NodeJS.Supervisor` error, or SSR silently fails in production.

**Cause:** `ssr_module` is not set to `LiveSvelte.SSR.NodeJS` in production config, or the SSR bundle (`priv/svelte/server.js`) is missing.

**Fix:**
1. Ensure `config/prod.exs` has:
   ```elixir
   config :live_svelte, ssr_module: LiveSvelte.SSR.NodeJS
   ```

2. Ensure the SSR bundle was built:
   ```bash
   MIX_ENV=prod mix assets.build && MIX_ENV=prod mix compile
   ```

3. Check that `NodeJS.Supervisor` is in `application.ex`:
   ```elixir
   {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}
   ```

## Svelte 4 Syntax Errors

**Symptom:** Component fails with unexpected syntax errors like `export let` or `<script context="module">`.

**Cause:** The component uses Svelte 4 syntax which is not supported in LiveSvelte's Svelte 5 setup.

**Fix:** Migrate to Svelte 5 runes:

| Svelte 4 | Svelte 5 |
|----------|----------|
| `export let count` | `let { count } = $props()` |
| `let x = 0` (reactive) | `let x = $state(0)` |
| `$: doubled = x * 2` | `let doubled = $derived(x * 2)` |
| `import { onMount } from 'svelte'` | same (unchanged) |

## SSR Not Working in Development

**Symptom:** Components render without SSR HTML even with `ssr: true` in config.

**Cause:** `vite_host` is not reachable or Vite dev server isn't running.

**Fix:** Ensure `mix phx.server` starts the Vite watcher and that asset URLs point at the Vite dev server. In `config/dev.exs` your endpoint must have:

1. **`static_url: [host: "localhost", port: 5173]`** — so script/link tags and the HMR client load from Vite (port 5173).
2. **A `:vite` watcher** — so the Vite dev server is started with `mix phx.server` and `PhoenixVite.Components.has_vite_watcher?/1` returns true.

Example (phoenix_vite with npm):

```elixir
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"

config :my_app, MyAppWeb.Endpoint,
  static_url: [host: "localhost", port: 5173],
  watchers: [
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    vite: {PhoenixVite.Npm, :run, [:vite, ~w(dev)]}
  ]
```

Without these, the layout serves built assets from `priv/static` and Svelte/CSS changes do not hot-reload.
