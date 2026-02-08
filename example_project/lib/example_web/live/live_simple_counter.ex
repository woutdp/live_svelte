defmodule ExampleWeb.LiveSimpleCounter do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4">
          Simple Counter Demo
        </h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Same LiveView state drives the native counter and both Svelte components.
        </p>

        <div class="flex flex-col gap-8">
          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                LiveView (native)
              </span>
              <div class="flex flex-row items-center justify-center gap-6 py-2">
                <span class="text-4xl font-bold tabular-nums text-brand"><%= @number %></span>
                <button class="btn btn-sm bg-brand text-white border-0 hover:opacity-90" phx-click="increment">
                  +1
                </button>
              </div>
            </div>
          </section>

          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                LiveSvelte
              </span>
              <div class="flex flex-wrap gap-6 justify-center py-4">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-xs text-base-content/50">Component 1</span>
                  <.svelte id="counter-1" name="SimpleCounter" props={%{number: @number}} socket={@socket} />
                </div>
                <div class="flex flex-col items-center gap-2">
                  <span class="text-xs text-base-content/50">Component 2</span>
                  <.svelte id="counter-2" name="SimpleCounter" props={%{number: @number}} socket={@socket} />
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :number, 10)}
  end

  def handle_event("increment", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
