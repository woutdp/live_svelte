defmodule ExampleWeb.LiveSlotsSimple do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.demo_page title="Simple slots" tag="h2" variant="compact">
      <:description>
        Phoenix slots are passed into the Svelte component as the default slot content.
      </:description>
      <.svelte name="Slots" socket={@socket}>
        Inside Slot
      </.svelte>
    </.demo_page>
    """
  end
end
