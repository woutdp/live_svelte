defmodule ExampleWeb.LiveSimpleCounter do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.demo_page title="Simple Counter Demo">
      <:description>
        Same LiveView state drives the native counter and both Svelte components.
      </:description>

      <.demo_card label="LiveView (native)">
        <div class="flex flex-row items-center justify-center gap-6 py-2">
          <span
            data-testid="live-simple-counter-value"
            class="text-4xl font-bold tabular-nums text-brand"
          >
            {@number}
          </span>
          <button
            data-testid="live-simple-counter-increment"
            class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
            phx-click="increment"
          >
            +1
          </button>
        </div>
      </.demo_card>

      <.demo_card label="LiveSvelte">
        <div class="flex flex-wrap gap-6 justify-center py-4">
          <div class="flex flex-col items-center gap-2">
            <span class="text-xs text-base-content/50">Component 1</span>
            <.svelte
              name="SimpleCounter"
              props={%{number: @number, initialClientValue: @initial_client_value}}
              socket={@socket}
            />
          </div>
          <div class="flex flex-col items-center gap-2">
            <span class="text-xs text-base-content/50">Component 2</span>
            <.svelte
              name="SimpleCounter"
              props={%{number: @number, initialClientValue: @initial_client_value}}
              socket={@socket}
            />
          </div>
        </div>
      </.demo_card>
    </.demo_page>
    """
  end

  def mount(_session, _params, socket) do
    initial_client =
      Application.get_env(:example, :simple_counter_initial_client_value, 1)

    {:ok,
     socket
     |> assign(:number, 10)
     |> assign(:initial_client_value, initial_client)}
  end

  def handle_event("increment", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
