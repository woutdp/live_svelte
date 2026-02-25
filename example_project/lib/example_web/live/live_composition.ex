defmodule ExampleWeb.LiveComposition do
  @moduledoc """
  LiveView demo for component composition with `useLiveSvelte()`.
  Demonstrates how any Svelte component in a composed tree can access the
  Phoenix hook via `useLiveSvelte()` — no prop drilling required.
  """
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, items: [])}
  end

  def handle_event("add-item", %{"name" => name}, socket) do
    {:noreply, assign(socket, items: [name | socket.assigns.items])}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">Composition (useLiveSvelte)</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        A parent Svelte component uses <code>useLiveSvelte()</code> to push events
        to the server. Child components stay pure — no LiveView knowledge needed.
      </p>
      <.svelte name="CompositionParent" props={%{items: @items}} socket={@socket} />
    </div>
    """
  end
end
