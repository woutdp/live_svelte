defmodule ExampleWeb.LiveComposition do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="CompositionParent" socket={@socket} />
    """
  end

  def handle_event("validate-item", %{"name" => name}, socket) do
    IO.puts(name)
    {:noreply, socket}
  end
end
