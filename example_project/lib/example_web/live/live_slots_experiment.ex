defmodule ExampleWeb.LiveSlotsExperiment do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="SlotsExperiment">
      Inside Slot
    </.svelte>
    """
  end
end
