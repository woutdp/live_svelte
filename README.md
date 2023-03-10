<div align="center">

# LiveSvelte

Render Svelte directly into Phoenix LiveView with E2E reactivity.

![logo](https://github.com/woutdp/live_svelte/blob/master/logo.png?raw=true)

[Features](#features) •
[Demo](#demo) •
[Installation](#installation) •
[Usage](#usage)

</div>

## Features

- End-To-End Reactivity
- Server-Side Rendered (SSR) Svelte
- Svelte Preprocessing Support with [svelte-preprocess](https://github.com/sveltejs/svelte-preprocess)
- Tailwind Support
- _Experimental_ Slot Interoperability

## Demo

You can find the code for this in `/examples/breaking_news`.

News items are synced with the server while the speed is only client side (but could be server side if desired).

https://user-images.githubusercontent.com/3637265/221381302-c9ff31fb-77a0-44f2-8c79-1a1a6b7e5893.mp4

## Why LiveSvelte

Phoenix LiveView enables rich, real-time user experiences with server-rendered HTML.
It works by communicating any state changes through a websocket and updating the DOM in realtime.
You can get a really good user experience without ever needing to write any client side code.

LiveSvelte builds on top of Phoenix LiveView to allow for easy client side state management while still allowing for communication over the websocket.

## Docs

- [HexDocs](https://hexdocs.pm/live_svelte)
- [HexPackage](https://hex.pm/packages/live_svelte)
- [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Installation

1. Add `live_svelte` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:live_svelte, "~> 0.2.0"}
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

4. Make sure you have `node` installed, you can verify this by running `node --version` in your project directory.

5. Finally, remove the `esbuild` configuration from `config/config.exs` and remove the dependency from the `deps` function in your `mix.exs`, and you are done!

### What did we do?

You'll notice a bunch of files get created in `/assets`, as well as some code changes in `/lib`. This mostly follows from the recommended way of using esbuild plugins, which we need to make this work. You can read more about this here: <https://hexdocs.pm/phoenix/asset_management.html#esbuild-plugins>

In addition we commented out some things such as the `esbuild` watcher configured in `dev.exs` that won't be needed anymore, you can delete these comments if desired.

## Usage

Svelte components need to go into the `assets/svelte/components` directory

- The `id` can be anything, but should be unique
- Set the `name` of the Svelte component in the `live_component`.
- Provide the `props` you want to use that should be reactive as a map to the props field

e.g. If your component is named `assets/svelte/components/Example.svelte`:

```elixir
def render(assigns) do
  ~H"""
  <.live_component
    module={LiveSvelte}
    id="UniqueId"
    name="Example"
    props={%{number: @number}}
  />
  """
end
```

If your component is in a directory, for example `assets/svelte/components/some-directory/SomeComponent.svelte` you need to include the directory in your name: `some-directory/SomeComponent`.

### Examples

Examples can be found in the `/examples` directory.

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
        pushEvent('set_number', { number: number + 1 }, () => {})

        // Note that we actually never set the number in the frontend!
        // We ONLY push the event to the server.
        // This is the E2E reactivity in action!
        // The number will automatically be updated through the LiveView websocket
    }

    function decrease() {
        pushEvent('set_number', { number: number - 1 }, () => {})
    }
</script>

<p>The number is {number}</p>
<button on:click={increase}>+</button>
<button on:click={decrease}>-</button>
```

#### Create a LiveView

```elixir
# `/lib/app_web/live/live_svelte.ex`
defmodule AppWeb.SvelteLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component
      module={LiveSvelte}
      id="Example"
      name="Example"
      props={%{number: @number}}
    />
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

## Caveats

### Slot Interoperability 

Slot interoperability is still experimental, **so use with caution!**

Svelte doesn't have an official way of setting the slot on mounting the Svelte object or updating it on subsequent changes, unlike props. This makes using slots from within Liveview on a Svelte component fragile.

The server side rendered initial Svelte rendering does have support for slots so that should work as expected.

Slots may eventually reach a state where it is stable, any help in getting there is appreciated. If you know a lot about the internals of Svelte your help may be invaluable here!

Any bugs related to this are welcome to be logged, PR's are especially welcome!

## Development

### Releasing

- Update the version in `README.md`
- Update the version in `package.json`
- Update the version in `mix.exs`

run `mix hex.publish`

## Credits
- [Ryan Cooke](https://dev.to/debussyman) - [E2E Reactivity using Svelte with Phoenix LiveView](https://dev.to/debussyman/e2e-reactivity-using-svelte-with-phoenix-liveview-38mf)
- [Svonix](https://github.com/nikokozak/svonix)
