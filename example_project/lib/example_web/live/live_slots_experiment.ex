defmodule ExampleWeb.LiveSlotsExperiment do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="SlotsExperiment" socket={@socket}>
      Inside Slot
    </.svelte>
    """
  end
end
