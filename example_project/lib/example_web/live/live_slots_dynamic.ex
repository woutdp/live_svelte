defmodule ExampleWeb.LiveSlotsDynamic do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.demo_page title="Dynamic slots" tag="h2" variant="compact">
      <:description>
        Default slot and named slot (:subtitle) both receive LiveView state; the button updates the number.
      </:description>
      <.svelte name="Slots" socket={@socket}>
        <div class="flex flex-wrap items-center gap-3">
          <button
            data-testid="slots-dynamic-increment"
            phx-click="increase"
            class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
          >
            Increment the number
          </button>
          <span data-testid="slots-dynamic-number" class="text-2xl font-bold tabular-nums text-brand">
            {@number}
          </span>
        </div>

        <:subtitle>
          <span
            data-testid="slots-dynamic-subtitle-number"
            class="text-xl font-semibold tabular-nums text-brand"
          >
            {@number}
          </span>
        </:subtitle>
      </.svelte>
    </.demo_page>
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :number, 1)}
  end

  def handle_event("increase", _, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
