defmodule ExampleWeb.LiveSigil do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~V"""
    <script>
      export let number
      let number2 = 5

      $: combined = number + number2
    </script>

    <h1 class="text-lg mb-4">Svelte template</h1>
    {number} + {number2} = {combined}

    <button phx-click="increment">+server</button>
    <button on:click={() => number2 += 1}>+client</button>

    <style lang="stylus">
      button
        background-color black
        color white
        padding 0.5rem 1rem
    </style>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :number, 10)}
  end

  def handle_event("increment", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
