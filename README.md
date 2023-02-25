<div align="center">

# LiveSvelte

Render Svelte directly into Phoenix LiveView with E2E reactivity.

![logo](https://github.com/woutdp/live_svelte/blob/master/logo.png?raw=true)

[Installation](#installation) •
[Usage](#usage)

</div>

## Features

- Server-Side Rendered (SSR) Svelte
- End-To-End Reactivity
- Svelte Preprocessing support with [svelte-preprocess](https://github.com/sveltejs/svelte-preprocess)
- Tailwind support

## Why LiveSvelte

Phoenix LiveView enables rich, real-time user experiences with server-rendered HTML.
It works by communicating any state changes through a websocket and updating the DOM in realtime.
You can get a really good user experience without ever needing to write any client side code.

LiveSvelte builds on top of Phoenix LiveView to allow for easy client side state management while still allowing for communication over the websocket.

## Docs

[HexDocs](https://hexdocs.pm/live_svelte)
[Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Installation

Add `live_svelte` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_svelte, "~> 0.1.0-rc1"}
  ]
end
```

Run the following in your terminal
```bash
mix deps.get
mix live_svelte.setup
```

Make sure you have Node installed, you can verify this by running `node --version` in your project directory.

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
    id="Example"
    name="Example"
    props={%{number: @number}}
  />
  """
end
```

If you component is in a directory, for example `assets/svelte/components/some-directory/SomeComponent.svelte` you need to include the directory in your name: `some-directory/SomeComponent`.

### Examples

Examples can be found in the example directory.

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

### Preprocessor

To use the preprocessor, install the desired preprocessor.

e.g. Typescript
```
cd assets && npm install --save-dev typescript
```

## Credits
- [Ryan Cooke](https://dev.to/debussyman) - [E2E Reactivity using Svelte with Phoenix LiveView](https://dev.to/debussyman/e2e-reactivity-using-svelte-with-phoenix-liveview-38mf)
- [Svonix](https://github.com/nikokozak/svonix)
