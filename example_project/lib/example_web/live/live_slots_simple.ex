defmodule ExampleWeb.LiveSlotsSimple do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Simple slots
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Phoenix slots are passed into the Svelte component as the default slot content.
      </p>
      <.svelte name="Slots" socket={@socket}>
        Inside Slot
      </.svelte>
    </div>
    """
  end
end
