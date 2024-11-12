defmodule ExampleWeb.LiveSlotsSimple do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Slots" socket={@socket}>
      Inside Slot
    </.svelte>
    """
  end
end
