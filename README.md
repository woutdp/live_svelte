<div align="center">

<img src="https://github.com/woutdp/live_svelte/blob/master/logo_3.png?raw=true" height="250" width="250" >

[![GitHub](https://img.shields.io/github/stars/woutdp/live_svelte?style=social)](https://github.com/woutdp/live_svelte)
[![Hex.pm](https://img.shields.io/hexpm/v/live_svelte.svg)](https://hex.pm/packages/live_svelte)

Svelte inside Phoenix LiveView with seamless end-to-end reactivity

[Features](#features) •
[Resources](#resources) •
[Demo](#demo) •
[Installation](#installation) •
[Usage](#usage) •
[Deployment](#deployment)

</div>

<!-- MDOC !-->

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Svelte
-   🪄 **Sigil** as an [Alternative LiveView DSL](#livesvelte-as-an-alternative-liveview-dsl)
-   ⭐ **Svelte Preprocessing** Support with [svelte-preprocess](https://github.com/sveltejs/svelte-preprocess)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🦥 **Slot Interoperability**
-   📘 **TypeScript** — client assets in TypeScript; public API is type-safe with exported type definitions for consumers

## Resources

-   [HexDocs](https://hexdocs.pm/live_svelte)
-   [HexPackage](https://hex.pm/packages/live_svelte)
-   [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)
-   [Blog Post](https://wout.space/notes/live-svelte)
-   [YouTube Introduction](https://www.youtube.com/watch?v=JMkvbW35QvA)

## Demo

For a full intro and demo check out the [YouTube introduction](https://www.youtube.com/watch?v=JMkvbW35QvA)

`/examples/advanced_chat`

https://user-images.githubusercontent.com/3637265/229902870-29166253-3d18-4b24-bbca-83c4b6648578.webm

<br />
Svelte handles the look and feel of the chat, while LiveView takes care of syncing. E2E reactivity to the Svelte component so we don't really need to fetch anything! The 'login' to enter your name is a simple LiveView form. Hybrid!

---

`/examples/breaking_news`

https://user-images.githubusercontent.com/3637265/229902860-f7ada6b4-4a20-4105-9ee9-79c0cbad8d72.webm

<br />
News items are synced with the server while the speed is only client side.

## Why LiveSvelte

Phoenix LiveView enables rich, real-time user experiences with server-rendered HTML.
It works by communicating any state changes through a websocket and updating the DOM in realtime.
You can get a really good user experience without ever needing to write any client side code.

LiveSvelte builds on top of Phoenix LiveView to allow for easy client side state management while still allowing for communication over the websocket.

### Reasons why you'd use LiveSvelte

-   You have (complex) local state
-   You want to take full advantage of Javascript's ecosystem
-   You want to take advantage of Svelte's animations
-   You want scoped CSS
-   You like Svelte and its DX :)

## Requirements

For Server-Side Rendering (SSR) to work you need `node` (version 19 or later) installed in your environment.

Make sure you have it installed in production too. You might be using `node` in the build step, but it might actually not be installed in your production environment.

You can make sure you have `node` installed by running `node --version` in your project directory.

If you don't want SSR, you can disable it by not setting `NodeJS.Supervisor` in `application.ex`. More on that in the [SSR](#ssr-server-side-rendering) section of this document.

## Installation

_If you're updating from an older version, make sure to check the `CHANGELOG.md` for breaking changes._

LiveSvelte uses [Vite](https://vite.dev/) for building and [phoenix_vite](https://github.com/LostKobrakai/phoenix_vite) to integrate it with Phoenix. The layout uses `PhoenixVite.Components.assets`; in development the endpoint runs a Vite watcher and points asset URLs at the Vite dev server so Svelte and CSS changes hot-reload with no extra terminal. The recommended way to install is via the [Igniter](https://github.com/ash-project/igniter) installer, which configures phoenix_vite (including the dev watcher and `static_url`) and all LiveSvelte steps.

### Option A — Igniter installer (recommended)

Requires Phoenix 1.8+ and Node.js 19+.

#### New project

```bash
mix archive.install hex igniter_new
mix igniter.new my_app --with phx.new --install live_svelte
cd my_app
mix setup
mix phx.server
```

#### Existing project

Igniter must be present in the project's deps before the installer can run.

1. Add igniter to `mix.exs`:

```elixir
defp deps do
  [
    # ... existing deps ...
    {:igniter, "~> 0.6"}
  ]
end
```

2. Fetch and run the installer (this adds `live_svelte`, configures [phoenix_vite](https://github.com/LostKobrakai/phoenix_vite), Vite, app.js, html_helpers, SSR, layout with `PhoenixVite.Components.assets`, and more):

```bash
mix deps.get
mix igniter.install live_svelte
```

3. Install npm packages and build assets:

```bash
mix assets.setup     # phoenix_vite.npm assets install
mix assets.build     # Vite client + SSR builds (or run mix setup to do both)
```

4. Start the server:

```bash
mix phx.server
```

With phoenix_vite, the layout uses `PhoenixVite.Components.assets` and the endpoint uses `PhoenixVite.Plug`; no separate Vite terminal is required for dev — phoenix_vite integrates the Vite dev server.

Visit `http://localhost:4000/svelte_demo` to confirm the demo Svelte component is working.

Add `--bun` to use Bun instead of npm/npx:

```bash
mix igniter.install live_svelte --bun
```

---

### Option B — Manual installation

Use this if you prefer not to use Igniter, or need full control over the configuration.

**1.** Add dependencies to `mix.exs`:

```elixir
defp deps do
  [
    {:live_svelte, "~> 0.17"}
  ]
end
```

**2.** Fetch deps:

```bash
mix deps.get
```

**3.** Add `import LiveSvelte` in `html_helpers/0` inside `lib/<app_name>_web.ex`:

```elixir
defp html_helpers do
  quote do
    # ...
    import LiveSvelte
    # ...
  end
end
```

**4.** Add phoenix_vite and configure mix aliases (or use the Igniter installer which does this). With phoenix_vite:

```elixir
# mix.exs deps
{:phoenix_vite, "~> 0.4"}

# config/config.exs
config :phoenix_vite, PhoenixVite.Npm,
  assets: [args: [], cd: __DIR__],
  vite: [
    args: ~w(exec -- vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

# mix.exs aliases
"assets.setup": ["phoenix_vite.npm assets install"],
"assets.build": [
  "phoenix_vite.npm vite build --manifest --emptyOutDir true",
  "phoenix_vite.npm vite build --ssrManifest --emptyOutDir false --ssr js/server.js --outDir ../priv/svelte"
],
"assets.deploy": ["assets.build", "phx.digest"]
```

Use `PhoenixVite.Components.assets` in your root layout and `import PhoenixVite.Plug` + `plug :favicon, dev_server: {PhoenixVite.Components, :has_vite_watcher?, [__MODULE__]}` in the endpoint. Without phoenix_vite, use `LiveSvelte.Reload.vite_assets` in the layout and run Vite manually.

**For instant Svelte/CSS HMR**, add to your endpoint in `config/dev.exs`: `static_url: [host: "localhost", port: 5173]` and in `watchers` add `vite: {PhoenixVite.Npm, :run, [:vite, ~w(dev)]}`. The Igniter installer does this for you; if you add phoenix_vite or LiveSvelte manually, add these so the layout serves assets from the Vite dev server and HMR works.

**5.** Update `assets/vite.config.mjs` to add the Svelte and LiveSvelte plugins:

```js
import { svelte } from "@sveltejs/vite-plugin-svelte"
import liveSveltePlugin from "live_svelte/vitePlugin"

// Inside defineConfig plugins array:
plugins: [
  svelte({ compilerOptions: { css: "injected" } }),
  liveSveltePlugin({ entrypoint: "./js/server.js" }),
  // ... existing plugins
]
```

**6.** Add `ssr: { noExternal: process.env.NODE_ENV === "production" ? true : undefined }` to the main `vite.config.mjs` so the same config is used for both client and SSR builds. The SSR build is run via `phoenix_vite.npm vite build --ssr js/server.js --outDir ../priv/svelte` (see aliases above). No separate `vite.ssr.config.js` is required when using phoenix_vite.

**7.** Create `assets/js/server.js`:

```js
import { getRender } from "live_svelte"
import Components from "virtual:live-svelte-components"
export const render = getRender(Components)
```

**8.** Update `assets/js/app.js` to wire in the LiveSvelte hooks:

```js
import { getHooks } from "live_svelte"
import Components from "virtual:live-svelte-components"

// Update your LiveSocket hooks:
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ...getHooks(Components) },
  // ...
})
```

**9.** Update `assets/package.json` to add Svelte dependencies:

```json
{
  "dependencies": {
    "live_svelte": "file:./deps/live_svelte"
  },
  "devDependencies": {
    "svelte": "^5.0.0",
    "@sveltejs/vite-plugin-svelte": "^5.0.0"
  }
}
```

**10.** Add SSR configuration to `config/config.exs`, `config/dev.exs`, and `config/prod.exs`:

```elixir
# config/config.exs
config :live_svelte, ssr: true

# config/dev.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.ViteJS,
  vite_host: "http://localhost:5173"

# config/prod.exs
config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true
```

**11.** Add `NodeJS.Supervisor` to `lib/<app_name>/application.ex`:

```elixir
children = [
  {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
  # ... existing children
]
```

**12.** For Tailwind support, add `@source "../svelte";` to `assets/css/app.css`.

**13.** Install npm packages and build:

```bash
mix assets.setup
mix assets.build
mix phx.server
```

## Usage

Svelte components need to go into the `assets/svelte` directory

Attributes:

-   `name`: Specify the Svelte component
-   `props` _(Optional)_: Provide the `props` you want to use that should be reactive as a map to the props field
-   `class` _(Optional)_: Provide `class` to set the class attribute on the root svelte element
-   `ssr` _(Optional)_: Set `ssr` to `false` to disable server-side rendering

e.g. If your component is named `assets/svelte/Example.svelte`:

```elixir
def render(assigns) do
  ~H"""
  <.svelte name="Example" props={%{number: @number}} socket={@socket} />
  """
end
```

If your component is in a directory, for example `assets/svelte/some-directory/SomeComponent.svelte` you need to include the directory in your name: `some-directory/SomeComponent`.

### The Components Macro

There is also an Elixir macro which checks your `assets/svelte` folder for any Svelte components, and injects local function `def`s for those components into the calling module.

This allows for an alternative, more JSX-like authoring experience inside Liveviews.

e.g. in the below example, a Svelte component called `Example` is available to be called inside the Liveview template:

```elixir
use LiveSvelte.Components

def render(assigns) do
  ~H"""
  <.Example number={@number} socket={@socket} />
  """
end
```

### Examples

Examples can be found in the `/examples` and `/example_project` directories.

Most of the `/example_project` examples are visible in the [YouTube demo video](https://www.youtube.com/watch?v=JMkvbW35QvA).

I recommend cloning `live_svelte` and running the example project in `/example_project` by running the following commands:

```bash
git clone https://github.com/woutdp/live_svelte.git
# set up and run the example project
cd live_svelte/example_project
mix setup
mix phx.server
```

The example project uses phoenix_vite: `mix phx.server` starts both Phoenix and the Vite dev server, so Svelte/CSS changes hot-reload. Server will be running on `localhost:4000`. If you want to change the port, edit `example_project/config/dev.exs` and change the `http` config.

If you have examples you want to add, feel free to create a PR, I'd be happy to add them.

#### Create a Svelte component

```svelte
<script>
    // The number prop is reactive,
    // this means if the server assigns the number, it will update in the frontend
    export let number = 1
    // live contains all exported LiveView methods available to the frontend
    export let live

    function increase() {
        // This pushes the event over the websocket
        // The last parameter is optional. It's a callback for when the event is finished.
        // You could for example set a loading state until the event is finished if it takes a longer time.
        live.pushEvent("set_number", {number: number + 1}, () => {})

        // Note that we actually never set the number in the frontend!
        // We ONLY push the event to the server.
        // This is the E2E reactivity in action!
        // The number will automatically be updated through the LiveView websocket
    }

    function decrease() {
        live.pushEvent("set_number", {number: number - 1}, () => {})
    }
</script>

<p>The number is {number}</p>
<button on:click={increase}>+</button>
<button on:click={decrease}>-</button>
```

_Note: that here we use the `pushEvent` function, but you could also use `phx-click` and `phx-value-number` if you wanted._

The following methods are available on `live`:

-   `pushEvent`
-   `pushEventTo`
-   `handleEvent`
-   `removeHandleEvent`
-   `upload`
-   `uploadTo`

These need to be run on the client, they can't be run in SSR. Either make sure they're called on an action (e.g. clicking a button) or wrap them with `onMount`.

More about this in the [LiveView documentation on js-interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)

#### Create a LiveView

```elixir
# `/lib/app_web/live/live_svelte.ex`
defmodule AppWeb.SvelteLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Example" props={%{number: @number}} socket={@socket} />
    """
  end

  def handle_event("set_number", %{"number" => number}, socket) do
    {:noreply, assign(socket, :number, number)}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :number, 5)}
  end
end
```

```elixir
# `/lib/app_web/router.ex`
import Phoenix.LiveView.Router

scope "/", AppWeb do
  ...
  live "/svelte", SvelteLive
  ...
end
```

### LiveSvelte As An Alternative LiveView DSL

[Blogpost on the topic](https://wout.space/notes/live-svelte-as-liveview-dsl)

We can go one step further and use LiveSvelte as an alternative to the standard LiveView DSL. This idea is inspired by [Surface UI](https://surface-ui.org/).

Take a look at the following example:

```elixir
defmodule ExampleWeb.LiveSigil do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~V"""
    <script>
      export let number = 5
      let other = 1

      $: combined = other + number
    </script>

    <p>This is number: {number}</p>
    <p>This is other: {other}</p>
    <p>This is other + number: {combined}</p>

    <button phx-click="increment">Increment</button>
    <button on:click={() => other += 1}>Increment</button>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :number, 1)}
  end

  def handle_event("increment", _value, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
```

Use the `~V` sigil instead of `~H` and your LiveView will be Svelte instead of an HEEx template.

#### Installation

1. If it's not already imported inside `html_helpers/0`, add `import LiveSvelte` inside the `live_view` function in your project, this can be found in `/lib/<app_name>_web.ex`:

```elixir
def live_view do
  quote do
    use Phoenix.LiveView,
      layout: {ExampleWeb.Layouts, :app}

    import LiveSvelte

    unquote(html_helpers())
  end
end
```

2. Ignore build files in your `.gitignore`. The sigil will create Svelte files that are then picked up by Vite, these files don't need to be included in your git repo:

```gitignore
# Ignore automatically generated Svelte files by the ~V sigil
/assets/svelte/_build/
```

#### Neovim Treesitter Config

To enable syntax highlighting in Neovim with Treesitter, create the following file:

`~/.config/nvim/after/queries/elixir/injections.scm`

```
; extends

; Svelte
(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "V")
 (#set! injection.language "svelte"))
```

For Neovim Treesitter version below v0.9:

```
; extends

; Svelte
(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @svelte
(#eq? @_sigil_name "V"))
```

Also make sure Svelte and Elixir is installed in Treesitter.

#### Options

Options can be passed in the mount by setting `svelte_opts`, check the following example:

```elixir
def mount(_params, _session, socket) do
  {:ok, assign(socket, some_value: 1, svelte_opts: %{ssr: false, class: "example-class"})}
end
```

### LiveView Live Navigation Events

Inside Svelte you can define [Live Navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html) links. These links navigate from one LiveView to the other without refreshing the page.

For example this can be useful when you have a Svelte store and you want this store state to remain during navigation. Example of Svelte store usage can be found in `/examples/store`.

`push_navigate`

```svelte
<a href="/your-liveview-path" data-phx-link="redirect" data-phx-link-state="push">Redirect</a>
```

`push_patch`

```svelte
<a href="/your-liveview-path" data-phx-link="patch" data-phx-link-state="push">Patch</a>
```

### LiveView JavaScript Interoperability

LiveView allows for a bunch of interoperability which you can read more about here:
<https://hexdocs.pm/phoenix_live_view/js-interop.html>

### Preprocessor

To use the preprocessor, install the desired preprocessor.

e.g. Typescript

```
cd assets && npm install --save-dev typescript
```

### SSR (Server-Side Rendering)

If you're unfamiliar with SSR (Server-Side Rendering), it is a feature of Svelte to... render Svelte on the server. This means on first page load you get to see HTML instead of a blank page. Immediately after the first page load the page is '[hydrated](https://www.youtube.com/watch?v=D46aT3mx9LU)', which is a fancy word for adding reactivity to your component. This happens in the background, you don't notice this step happening.

The way LiveSvelte updates itself through LiveView is by letting Svelte handle all the HTML edits. Usually LiveView would edit the HTML by passing messages through the websocket. In our case we only pass the data we provided in the props attribute to Svelte through the websocket. No HTML is being touched by LiveView, Svelte takes care of that.

Like mentioned, without SSR you'd see a brief flash of un-rendered content. Sometimes you can get away with not rendering Svelte on the server, for example when your Svelte component doesn't do any rendering on first page load and needs to be manually toggled for visibility by the user. Or when it is a component that has no visual component to it like tracking your mouse cursor and sending it back to the server.

In theses cases you can turn off SSR.

**Important: Set NODE_ENV to production in production deployments**

When deploying your application to production, you must set the `NODE_ENV` environment variable to `production`. If this is not done, your application may experience a memory leak and significantly reduced performance during SSR. For Docker deployments, you can add the following line to your production Dockerfile as an example:

```
ENV NODE_ENV production
```

#### Disabling SSR

SSR is enabled by default when you install LiveSvelte. If you don't want to use Server-Side Rendering for Svelte, you can disable it in the following ways:

##### Globally

If you don't want to use SSR on any component you can disable it globally.

There are 2 ways of doing this

-   Don't include the `NodeJS` supervisor in the `application.ex` file
    or
-   Add `ssr: false` to the `live_svelte` config in your `config.exs` file like so:

```elixir
config :live_svelte,
  ssr: false
```

##### Component

To disable SSR on a specific component, set the `ssr` property to false. Like so:

```
<.svelte name="Example" ssr={false} />
```

### Auto-generated IDs and loops

When the same Svelte component is rendered multiple times (e.g. in a `for` loop),
LiveSvelte automatically generates unique, stable DOM IDs so that LiveView can
correctly reconcile hook elements across re-renders.

**How it works (priority order):**

1. **Explicit `id`** — if you pass `id="my-id"`, that value is used as-is.
2. **Explicit `key`** — if you pass `key={index}`, the DOM id becomes `ComponentName-<key>`.
3. **Auto-detected identity from props** — LiveSvelte inspects the `props` map for
   common identity keys (`:id`, `:key`, `:index`, `:idx` and their string equivalents).
   When found, the value is appended to the component name to form a deterministic ID.
4. **Counter fallback** — when none of the above apply, a simple per-name counter
   produces sequential IDs (`Name`, `Name-1`, `Name-2`, …). This works for
   standalone components but is **not** reliable inside comprehensions.

For most loops you already pass an `index` or `id` in your props, so IDs are
generated automatically with no extra work:

```elixir
<%= for {item, index} <- Enum.with_index(@list) do %>
  <%!-- index in props → auto-generates ids: "Card-0", "Card-1", … --%>
  <.svelte name="Card" props={%{index: index, color: @color}} />
<% end %>
```

If your props don't contain a natural identity key, use the `key` attribute:

```elixir
<%= for {item, index} <- Enum.with_index(@list) do %>
  <.svelte name="Chart" key={index} props={%{data: item.data}} />
<% end %>
```

### Props diffing (change tracking)

When props diffing is enabled, LiveSvelte sends only **changed** props to the client on updates, so unchanged props are not included in the payload and updates are minimal.

-   **Config:** `config :live_svelte, enable_props_diff: true` (default). Set to `false` to always send full props.
-   **Per component:** Use the `diff` attribute to opt out on a single component: `<.svelte name="Example" props={@props} diff={false} />`.

On the initial render or when the socket is disconnected, full props are always sent. When connected and diffing is on, only keys that changed (compared to the previous render) are sent, and the client merges them into existing state.

### JSON Library

LiveSvelte uses Erlang/OTP 27's native `:json` module by default for JSON encoding.
This provides excellent performance without requiring external dependencies.

**Note:** LiveSvelte requires Elixir 1.17+ and OTP 27+ for the native JSON module.

#### Using Jason or Poison

If you prefer to use Jason, Poison, or another JSON library, configure it in your `config.exs`:

```elixir
# config/config.exs
config :live_svelte, json_library: Jason
```

Add the dependency to your `mix.exs`:

```elixir
# mix.exs
defp deps do
  [
    {:live_svelte, "~> 0.17"},
    {:jason, "~> 1.2"}  # or {:poison, "~> 5.0"}
  ]
end
```

The JSON library must implement `encode!/1` that accepts any Elixir term and returns a JSON string.

#### Struct Encoding

The native JSON encoder automatically converts structs to maps before encoding. This means
you don't need `@derive Jason.Encoder` when using the default native JSON encoder.

If you're using Jason and need custom struct encoding behavior, see the
[Structs and Ecto](#structs-and-ecto) section for details on `@derive Jason.Encoder`.

#### LiveSvelte.Encoder protocol

All props pass through the `LiveSvelte.Encoder` protocol before JSON encoding. You can control which struct fields are sent to Svelte with `@derive`:

```elixir
defmodule User do
  @derive {LiveSvelte.Encoder, except: [:password]}
  defstruct [:name, :email, :password]
end
```

- `@derive LiveSvelte.Encoder` — encode all fields except `__struct__`
- `@derive {LiveSvelte.Encoder, only: [:name, :email]}` — encode only listed keys
- `@derive {LiveSvelte.Encoder, except: [:password]}` — encode all except listed keys

Phoenix.HTML.Form, Ecto.Changeset, and Phoenix LiveView upload structs have built-in encoders. Date/Time types are encoded as ISO8601 strings.

For efficient updates when only some props change, use the built-in **props diffing** (see [Configuration](https://hexdocs.pm/live_svelte/configuration.html)) and JSON Patch support; the former `live_json` integration has been removed.

### Structs and Ecto

LiveSvelte serializes data passed in props to JSON so it can be handled by JavaScript.

**With native JSON (default):** Structs are automatically converted to maps. No additional configuration needed.

**With Jason:** Jason doesn't know how to handle structs by default, so you need to define it yourself using `@derive`.

#### Structs (Jason only)

If you're using Jason and have a struct like this:

```elixir
defmodule User do
  defstruct name: "John", age: 27, address: "Main St"
end
```

You must define `@derive`

```elixir
defmodule User do
  @derive Jason.Encoder
  defstruct name: "John", age: 27, address: "Main St"
end
```

Be careful though, as you might accidentally leak certain fields you don't want the client to access, you can include which fields to serialize:

```elixir
defmodule User do
  @derive {Jason.Encoder, only: [:name, :age]}
  defstruct name: "John", age: 27, address: "Main St"
end
```

#### Ecto (Jason only)

When using Jason with Ecto schemas, it's important to _also_ omit the `__meta__` field as it's not serializable.

Check out the following example:

```elixir
defmodule Example.Planets.Planet do
  use Ecto.Schema
  import Ecto.Changeset
  @derive {Jason.Encoder, except: [:__meta__]}

  schema "planets" do
    field :diameter, :integer
    field :mass, :integer
    field :name, :string

    timestamps()
  end

  ...
end
```

#### Documentation

More documentation on the topic:

-   [HexDocs](https://hexdocs.pm/jason/Jason.Encoder.html)
-   [GitHub](https://github.com/michalmuskala/jason#encoders)

### Slots

You can slot Elixir inside a LiveSvelte component like so:

```elixir
<.svelte name="Example">
  <p>Slot content</p>
</.svelte>
```

And in the Svelte file it will look like this:

```svelte
<script>
    let {children}: = $props()
</script>

<i>Opening</i>
  {@render children?.()}
<i>Closing</i>
```

Named slots also work:

```elixir
<.svelte name="Example">
  Main content
  <:subtitle>
    <p>Slot content</p>
  </:subtitle>
</.svelte>
```

```svelte
<script>
    let {children, subtitle}: = $props()
</script>

<i>Opening</i>
  {@render children()}
  <h2>{@render subtitle()}</h2>
<i>Closing</i>
```

This works because of the Snippet API provided by Svelte. Be careful though, it's a new feature that might not be working 100% of the time, I'd love to see what limitations you hit with it. One limitation is that you can't slot other Svelte components.

> ℹ️ **Note: Slotted Content is wrapped with a `div`**
>
> LiveSvelte wraps all slotted content in a `<div>` element.
> This is a limitation to how `createRawSnippet` works in Svelte, which is used under the hood in LiveSvelte to make this feature work.

### Showing fallback content with :loading

When SSR is disabled, a full‑page refresh briefly shows a blank content before Svelte finishes loading.
Use the `:loading` slot to render a placeholder during that gap:

```elixir
<.svelte name="Example" ssr={false}>
  <:loading>
    <p>Until your LiveSvelte component renders client-side, this will be displayed</p>
  </:loading>
</.svelte>
```


## Caveats

### "Secret State"

With LiveView, it's easy to keep things secret. Let's say you have a conditional that only renders when something is `true`, in LiveView there's no way to know what that conditional will show until it is shown, that's because the HTML is sent over the wire.

With LiveSvelte, we're dealing with JSON being sent to Svelte, which in turn takes that JSON data and conditionally renders something, even if we don't set the conditional to `true`, the Svelte code will contain code on what to show when the conditional turns `true`.

In a lot of scenarios this is not an issue, but it can be and is something you should be aware of.

## LiveSvelte Development

### Local Setup

#### Example Project

You can use `/example_project` as a way to test `live_svelte` locally.

#### Custom Project

You can also use your own project.

Clone `live_svelte` to the parent directory of the project you want to test it in.

Inside `mix.exs`

```elixir
{:live_svelte, path: "../live_svelte"},
```

Inside `assets/package.json`

```javascript
"live_svelte": "file:../../live_svelte",
```

### Development Workflow

LiveSvelte ships TypeScript source directly — there are no pre-built distribution files. Consumers compile the library source through their own Vite pipeline via the `live_svelte` package alias.

When working on the library source in `assets/js/live_svelte/`, rebuild the example project so Vite picks up the changes:

```bash
# From example_project/ — rebuild after library source changes:
mix assets.build && mix compile
```

The example project uses phoenix_vite, so a single `mix phx.server` starts both Phoenix and the Vite dev server; Svelte and library changes hot-reload with no second terminal.

**Type checking:** The LiveSvelte client library is written in TypeScript with a type-safe public API (no `any` in exported types). Consumers get type hints via the package `types` entry. From the library repo, run `npm run typecheck` in `live_svelte/assets` to run `tsc --noEmit`.

### Releasing

-   Update the version in `README.md`
-   Update the version in `package.json`
-   Update the version in `mix.exs`
-   Update the changelog

Run:

```bash
mix hex.publish
```

-   Publish a tag for the latest version

## Deployment

Deploying a LiveSvelte app is the same as deploying a regular Phoenix app, except that you will need to ensure that `nodejs` (version 19 or later) is installed in your production environment.

The below guide shows how to deploy a LiveSvelte app to [Fly.io](https://fly.io/), but similar steps can be taken to deploy to other hosting providers.
You can find more information on how to deploy a Phoenix app [here](https://hexdocs.pm/phoenix/deployment.html).

> **Note:** For best performance and to avoid memory leaks, always set the `NODE_ENV` environment variable to `production` in your production environment.

### Deploying on Fly.io

The following steps are needed to deploy to Fly.io. This guide assumes that you'll be using Fly Postgres as your database. Further guidance on how to deploy to Fly.io can be found [here](https://fly.io/docs/elixir/getting-started/).

1. Generate a `Dockerfile`:

```bash
mix phx.gen.release --docker
```

2. Modify the generated `Dockerfile` to install `curl`, which is used to install `nodejs` (version 19 or greater), and also add a step to install our `npm` dependencies:

```diff
# ./Dockerfile

...

# install build dependencies
- RUN apt-get update -y && apt-get install -y build-essential git \
+ RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

+ # install nodejs for build stage
+ RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

...

COPY assets assets

+ # install all npm packages in assets directory
+ WORKDIR /app/assets
+ RUN npm install

+ # change back to build dir
+ WORKDIR /app

...

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
-  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
+  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl \
   && apt-get clean && rm -f /var/lib/apt/lists/*_*

+ # install nodejs for production environment
+ RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

...
```

Note: `nodejs` is installed BOTH in the build stage and in the final image. This is because we need `nodejs` to install our `npm` dependencies and also need it when running our app.

3. Launch your app with the Fly.io CLI:

```bash
fly launch
```

4. When prompted to tweak settings, choose `y`:

```bash
? Do you want to tweak these settings before proceeding? (y/N) y
```

This will launch a new window where you can tweak your launch settings. In the database section, choose `Fly Postgres` and enter a name for your database. You may also want to change your database to the development configuration to avoid extra costs. You can leave the rest of the settings as-is unless you want to change them.

Deployment will continue once you hit confirm.

5. Once the deployment completes, run the following command to see your deployed app!

```bash
fly apps open
```

## Svelte 4 -> Svelte 5 migration guide

Since version `0.15.0`, LiveSvelte supports Svelte 5. If you want to use Svelte 4, use version `0.14.0`. Note that Svelte 5 is backwards compatible with Svelte 4 for the most part, so even if you're using Svelte 4 syntax, with the latest version it should still work, and so there should be few reasons why to stay on version `0.14.0`.

To migrate your project from `0.14.0` to `0.15.0` you need to follow the following 3 steps:

1. Update `mix.exs` and run `mix deps.get`

```elixir
# `mix.exs`
{:live_svelte, "0.15.0"}`
```

2. Update to the latest Svelte 5 in your package.json

```javascript
  // package.json
 "svelte": "^5",
```

3. Update your Vite configuration to use `@sveltejs/vite-plugin-svelte` with Svelte 5.
Refer to the installation guide for the current Vite setup.


## Credits

-   [Ryan Cooke](https://dev.to/debussyman) - [E2E Reactivity using Svelte with Phoenix LiveView](https://dev.to/debussyman/e2e-reactivity-using-svelte-with-phoenix-liveview-38mf)
-   [Svonix](https://github.com/nikokozak/svonix)
-   [Sveltex](https://github.com/virkillz/sveltex)

## Alternatives for other frontend frameworks

-   Vue: [LiveVue](https://github.com/Valian/live_vue)
-   React: [LiveReact](https://github.com/mrdotb/live_react)

## LiveSvelte Projects

-   [ash-svelte-flowbite](https://github.com/dev-guy/ash-svelte-flowbite)
-   [Local-First Todo App](https://github.com/tonydangblog/liveview-svelte-pwa)
-   [Beacon LiveAdmin](https://github.com/BeaconCMS/beacon_live_admin)
-   [TV Labs](https://tvlabs.ai/)

_Using LiveSvelte in a public project? Let me know and I'll add it to this list!_
