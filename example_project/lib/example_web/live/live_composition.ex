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
    <.demo_page title="Composition (useLiveSvelte)" tag="h2" variant="compact">
      <:description>
        A parent Svelte component uses <code>useLiveSvelte()</code> to push events
        to the server. Child components stay pure — no LiveView knowledge needed.
      </:description>
      <.svelte name="CompositionParent" props={%{items: @items}} socket={@socket} />
    </.demo_page>
    """
  end
end
