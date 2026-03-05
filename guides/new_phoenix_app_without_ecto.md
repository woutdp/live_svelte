# New Phoenix project without Ecto (Igniter + LiveSvelte)

Step-by-step guide to create a new Phoenix app **without Ecto** inside the `live_svelte` folder, using the Igniter installer and the local LiveSvelte library.

## Prerequisites

- Elixir 1.17+
- Node.js 19+ (or Bun)
- Phoenix 1.8+ (pulled in by Igniter)

## Step 1: Install the Igniter archive

From any directory:

```bash
mix archive.install hex igniter_new
```

## Step 2: Create the new Phoenix app inside `live_svelte`

Go to the `live_svelte` directory and run Igniter with `phx.new` and `--no-ecto`:

```bash
cd /home/gevera/Projects/elixir/phx_live/live_svelte
mix igniter.new my_app --with phx.new --with-args="--no-ecto" --install live_svelte
```

Replace `my_app` with your app name (e.g. `alan_app`). This creates `live_svelte/my_app/` with Phoenix (no Ecto) and LiveSvelte pre-installed.

To use **Bun** instead of npm:

```bash
mix igniter.new my_app --with phx.new --with-args="--no-ecto" --install live_svelte --bun
```

## Step 3: Use the local LiveSvelte library (development)

The installer adds LiveSvelte from Hex. To use the **local** LiveSvelte in this repo instead:

1. **Edit the new app’s `mix.exs`**  
   Find the `live_svelte` dependency and change it to a path dependency:

   ```elixir
   # Change from:
   # {:live_svelte, "~> 0.17.x"},
   # To:
   {:live_svelte, path: ".."},
   ```

2. **Edit the new app’s `package.json`**  
   Point `live_svelte` and Phoenix deps to the local/relative paths (same layout as `example_project` and the fixed `alan_app`):

   - `live_svelte`: use `"file:.."` (parent directory = LiveSvelte root).
   - Phoenix-related deps: use `"file:./deps/..."` (Mix puts them in `my_app/deps/`).

   Example:

   ```json
   "dependencies": {
     "live_svelte": "file:..",
     "phoenix": "file:./deps/phoenix",
     "phoenix_html": "file:./deps/phoenix_html",
     "phoenix_live_view": "file:./deps/phoenix_live_view",
     "topbar": "^3.0.0"
   },
   "devDependencies": {
     "phoenix_vite": "file:./deps/phoenix_vite",
     ...
   }
   ```

   If your `package.json` has `file:../deps/...`, change those to `file:./deps/...` and `live_svelte` to `file:..`.

## Step 4: Install dependencies and run

From the **new app** directory:

```bash
cd my_app
mix deps.get
mix assets.setup
mix phx.server
```

Open `http://localhost:4000` and visit `/svelte_demo` to confirm LiveSvelte works.

## Summary

| Step | Command / action |
|------|-------------------|
| 1 | `mix archive.install hex igniter_new` |
| 2 | `cd live_svelte` then `mix igniter.new my_app --with phx.new --with-args="--no-ecto" --install live_svelte` |
| 3 | In `my_app`: set `{:live_svelte, path: ".."}` in `mix.exs` and fix `package.json` to `live_svelte: "file:.."` and Phoenix deps to `file:./deps/...` |
| 4 | `cd my_app`, `mix deps.get`, `mix assets.setup`, `mix phx.server` |

Optional: add `--bun` to the `igniter.new` command to use Bun instead of npm.

---

## If `igniter.new` fails with "dependencies were not loaded"

Igniter can fail with:

```text
** (RuntimeError) cannot retrieve dependencies information because dependencies were not loaded.
Please invoke one of "deps.loadpaths", "loadpaths", or "compile" Mix task
```

That happens when it creates the new app and then tries to compile before the new project’s deps are loaded. The app directory (e.g. `my_app/`) is still created by `phx.new`; only the LiveSvelte install step didn’t run. You can finish setup by hand.

### Recover the existing app (e.g. `my_app`)

1. **Go into the new app and load deps:**

   ```bash
   cd live_svelte/my_app
   mix deps.get
   mix compile
   ```

2. **Add LiveSvelte and Phoenix Vite to `mix.exs`** in the `deps/0` list (and keep `igniter` if it’s there):

   ```elixir
   {:phoenix_vite, "~> 0.4"},
   {:live_svelte, path: ".."}
   ```

3. **Fetch deps and run the LiveSvelte installer:**

   ```bash
   mix deps.get
   mix igniter.install live_svelte
   ```

   Use `--bun` if you want Bun: `mix igniter.install live_svelte --bun`.

4. **Fix `package.json` for local LiveSvelte** (same as Step 3 in the main flow):

   - `"live_svelte": "file:.."`
   - Phoenix deps: `"file:./deps/phoenix"`, `"file:./deps/phoenix_html"`, `"file:./deps/phoenix_live_view"`
   - In devDependencies: `"phoenix_vite": "file:./deps/phoenix_vite"`

5. **Install assets and run:**

   ```bash
   mix assets.setup
   mix phx.server
   ```

---

## Alternative: create with `phx.new` then install LiveSvelte

To avoid `igniter.new` entirely (e.g. if the "dependencies were not loaded" error keeps happening):

1. **Create a Phoenix app without Ecto** from the `live_svelte` directory:

   ```bash
   cd live_svelte
   mix phx.new my_app --no-ecto
   ```

   (You need the `phx_new` archive: `mix archive.install hex phx_new`.)

2. **Add Igniter and LiveSvelte** in the new app’s `mix.exs` (in `deps/0`):

   ```elixir
   {:igniter, "~> 0.6", only: [:dev, :test]},
   {:phoenix_vite, "~> 0.4"},
   {:live_svelte, path: ".."}
   ```

3. **Install deps and run the LiveSvelte installer:**

   ```bash
   cd my_app
   mix deps.get
   mix igniter.install live_svelte
   ```

   Use `mix igniter.install live_svelte --bun` for Bun.

4. **Fix `package.json`** so the app uses the local LiveSvelte and local Phoenix deps (same as Step 3 above: `live_svelte` → `"file:.."`, Phoenix deps → `"file:./deps/..."`).

5. **Setup assets and run:**

   ```bash
   mix assets.setup
   mix phx.server
   ```

This way you never run `igniter.new`; you use `phx.new` and then `igniter.install live_svelte`.
