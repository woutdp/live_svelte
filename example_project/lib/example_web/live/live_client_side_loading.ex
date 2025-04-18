defmodule ExampleWeb.LiveClientSideLoading do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl bold mb-4">Examples of the loading slot</h1>
    <div class="flex flex-col gap-4">
      <div>
        <h2 class="text-xl">Client side</h2>
        <.svelte name="ClientSideLoading" ssr={false}>
          <:loading>
            <div class="animate-spin h-4 w-4 border-4 border-blue-500 rounded-full border-t-transparent"></div>
          </:loading>
        </.svelte>
      </div>

      <div>
        <h2 class="text-xl">Server side (should not be used)</h2>
        <p class="bold italic">This should flicker and throw a console warning</p>
        <.svelte name="ClientSideLoading" socket={@socket}>
          <:loading>
            <div class="animate-spin h-4 w-4 border-4 border-blue-500 rounded-full border-t-transparent"></div>
          </:loading>
        </.svelte>
      </div>
    </div>
    """
  end
end
