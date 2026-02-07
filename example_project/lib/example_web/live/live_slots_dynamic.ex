defmodule ExampleWeb.LiveSlotsDynamic do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Dynamic slots
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Default slot and named slot (:subtitle) both receive LiveView state; the button updates the number.
      </p>
      <.svelte name="Slots" socket={@socket}>
        <div class="flex flex-wrap items-center gap-3">
          <button phx-click="increase" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90">
            Increment the number
          </button>
          <span class="text-2xl font-bold tabular-nums text-brand"><%= @number %></span>
        </div>

        <:subtitle>
          <span class="text-xl font-semibold tabular-nums text-brand"><%= @number %></span>
        </:subtitle>
      </.svelte>
    </div>
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :number, 1)}
  end

  def handle_event("increase", _, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
