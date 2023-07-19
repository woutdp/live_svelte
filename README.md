<div align="center">

# LiveSvelte

[![GitHub](https://img.shields.io/github/stars/woutdp/live_svelte?style=social)](https://github.com/woutdp/live_svelte)
[![Hex.pm](https://img.shields.io/hexpm/v/live_svelte.svg)](https://hex.pm/packages/live_svelte)

Svelte inside Phoenix LiveView with seamless end-to-end reactivity

![logo](https://github.com/woutdp/live_svelte/blob/master/logo.png?raw=true)

[Features](#features) •
[Resources](#resources) •
[Demo](#demo) •
[Installation](#installation) •
[Usage](#usage)

</div>

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Svelte
-   🪄 **Sigil** as an [Alternative LiveView DSL](#livesvelte-as-an-alternative-liveview-dsl)
-   ⭐ **Svelte Preprocessing** Support with [svelte-preprocess](https://github.com/sveltejs/svelte-preprocess)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🤏 **live_json** Support
-   🦥 **Slot Interoperability** _(Experimental)_

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

1. Add `live_svelte` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:live_svelte, "~> 0.9.0"}
  ]
end
```

2. Adjust the `setup` and `assets.deploy` aliases in `mix.exs`:

```elixir
defp aliases do
  [
    setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
    ...,
    "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
  ]
end
```

3. Run the following in your terminal

```bash
mix deps.get
mix live_svelte.setup
```

4. Add `import LiveSvelte` in `html_helpers/0` inside `/lib/<app_name>_web.ex` like so:

```elixir
# /lib/<app_name>_web.ex

defp html_helpers do
  quote do

    # ...

    import LiveSvelte  # <-- Add this line

    # ...

  end
end
```

5. For tailwind support, add `"./svelte/**/*.svelte"` to `content` in the `tailwind.config.js` file

```javascript
...
content: [
  ...
  "./svelte/**/*.svelte"
],
...
```

6. Finally, remove the `esbuild` configuration from `config/config.exs` and remove the dependency from the `deps` function in your `mix.exs`, and you are done!

### What did we do?

You'll notice a bunch of files get created in `/assets`, as well as some code changes in `/lib`. This mostly follows from the recommended way of using esbuild plugins, which we need to make this work. You can read more about this here: <https://hexdocs.pm/phoenix/asset_management.html#esbuild-plugins>

In addition we commented out some things such as the `esbuild` watcher configured in `dev.exs` that won't be needed anymore, you can delete these comments if desired.

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
  <.svelte name="Example" props={%{number: @number}} />
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
  <.Example number={@number} />
  """
end
```

### Examples

Examples can be found in the `/examples` and `/example_project` directories.

Most of the `/example_project` examples are visible in the [YouTube demo video](https://www.youtube.com/watch?v=JMkvbW35QvA).

I recommend cloning `live_svelte` and running the example project in `/example_project` by running the following commands:

```
git clone https://github.com/woutdp/live_svelte.git
cd ./live_svelte/example_project
npm install --prefix assets
mix deps.get
mix phx.server
```

Server should be running on `localhost:4000`

If you have examples you want to add, feel free to create a PR, I'd be happy to add them.

#### Create a Svelte component

```svelte
<script>
    // The number prop is reactive,
    // this means if the server assigns the number, it will update in the frontend
    export let number = 1
    // pushEvent to ... push events to the server.
    export let pushEvent

    function increase() {
        // This pushes the event over the websocket
        // The last parameter is optional. It's a callback for when the event is finished.
        // You could for example set a loading state until the event is finished if it takes a longer time.
        pushEvent("set_number", {number: number + 1}, () => {})

        // Note that we actually never set the number in the frontend!
        // We ONLY push the event to the server.
        // This is the E2E reactivity in action!
        // The number will automatically be updated through the LiveView websocket
    }

    function decrease() {
        pushEvent("set_number", {number: number - 1}, () => {})
    }
</script>

<p>The number is {number}</p>
<button on:click={increase}>+</button>
<button on:click={decrease}>-</button>
```

_Note: that here we use the `pushEvent` function, but you could also use `phx-click` and `phx-value-number` if you wanted._

_`pushEventTo` is available too and works exactly the same way as specified in the [documentation](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)._

#### Create a LiveView

```elixir
# `/lib/app_web/live/live_svelte.ex`
defmodule AppWeb.SvelteLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Example" props={%{number: @number}} />
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

2. Ignore build files in your `.gitignore`. The sigil will create Svelte files that are then picked up by `esbuild`, these files don't need to be included in your git repo:

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

#### Disabling SSR

SSR is enabled by default when you install LiveSvelte. If you don't want to use Server-Side Rendering for Svelte, you have 2 options:

##### Globally

If you don't want to use SSR on any component you can disable it globally.
This will automatically be the case if you don't include the `NodeJS` supervisor in the `application.ex` file

##### Component

To disable SSR on a specific component, set the `ssr` property to false. Like so:

```
<.svelte name="Example" ssr={false} />
```

### live_json

LiveSvelte has support for [live_json](https://github.com/Miserlou/live_json).

By default, LiveSvelte sends your entire json object over the wire through LiveView. This can be expensive if your json object is big and changes frequently.

`live_json` on the other hand allows you to only send a _diff_ of the json to Svelte. This is very useful the bigger your json objects get.

Counterintuitively, you don't always want to use `live_json`. Sometimes it's cheaper to send your entire object again. Although diffs are small, they do add a little bit of data to your json. So if your json is relatively small, I'd recommend not using `live_json`, but it's something to experiment with for your use-case.

#### Usage

1. Install [live_json](https://github.com/Miserlou/live_json#installation)

2. Use `live_json` in your project with LiveSvelte. For example:

```elixir
def render(assigns) do
  ~H"""
    <.svelte name="Component" live_json_props={%{my_prop: @ljmy_prop}}/>
  """
end

def mount(_, _, socket) do
  # Get `my_big_json_object` somehow
  {:ok, LiveJson.initialize("my_prop", my_big_json_object)}
end

def handle_info(%Broadcast{event: "update", payload: my_big_json_object}, socket) do
  {:noreply, LiveJson.push_patch(socket, "my_prop", my_big_json_object)}
end
```

#### Example

You can find an example [here](https://github.com/woutdp/live_svelte/blob/master/example_project/lib/example_web/live/live_json.ex).

### Structs and Ecto

We use [Jason](https://github.com/michalmuskala/jason) to serialize any data you pass in the props so it can be handled by Javascript.
Jason doesn't know how to handle structs by default, so you need to define it yourself.

#### Structs

For example, if you have a regular struct like this:

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

#### Ecto

In ecto's case it's important to _also_ omit the `__meta__` field as it's not serializable.

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

## Caveats

### Slot Interoperability

Slot interoperability is still experimental, **so use with caution!**

Svelte doesn't have an official way of setting the slot on mounting the Svelte object or updating it on subsequent changes, unlike props. This makes using slots from within Liveview on a Svelte component fragile.

The server side rendered initial Svelte rendering does have support for slots so that should work as expected.

Slots may eventually reach a state where it is stable, any help in getting there is appreciated. If you know a lot about the internals of Svelte your help may be invaluable here!

Any bugs related to this are welcome to be logged, PR's are especially welcome!

### "Secret State"

With LiveView, it's easy to keep things secret. Let's say you have a conditional that only renders when something is `true`, in LiveView there's no way to know what that conditional will show until it is shown, that's because the HTML is sent over the wire.

With LiveSvelte, we're dealing with JSON being sent to Svelte, which in turn takes that JSON data and conditionally renders something, even if we don't set the conditional to `true`, the Svelte code will contain code on what to show when the conditional turns `true`.

In a lot of scenarios this is not an issue, but it can be and is something you should be aware of.

## Development

### Building Static Files

Make the changes in `/assets/js` and run:

```bash
mix assets.build
```

Or run the watcher:

```bash
mix assets.build --watch
```

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

### Releasing

-   Update the version in `README.md`
-   Update the version in `package.json`
-   Update the version in `mix.exs`
-   Update the changelog

Run:

```bash
mix hex.publish
```

## Credits

-   [Ryan Cooke](https://dev.to/debussyman) - [E2E Reactivity using Svelte with Phoenix LiveView](https://dev.to/debussyman/e2e-reactivity-using-svelte-with-phoenix-liveview-38mf)
-   [Svonix](https://github.com/nikokozak/svonix)
-   [Sveltex](https://github.com/virkillz/sveltex)

## LiveSvelte Projects

-   [Territoriez.io](https://territoriez.io)
-   [ash-svelte-flowbite](https://github.com/dev-guy/ash-svelte-flowbite)

_Using LiveSvelte in a public project? Let me know and I'll add it to this list!_
