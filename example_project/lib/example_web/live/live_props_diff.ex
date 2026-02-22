defmodule ExampleWeb.LivePropsDiff do
  @moduledoc """
  Demo for Tier 1 props diffing: only changed assigns are sent when diff is enabled.
  Two Svelte components side by side—one with diff on (default), one with diff off—
  so you can compare payloads in DevTools (data-props) after clicking Increment A/B/C.
  """
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:a, 1)
     |> assign(:b, 2)
     |> assign(:c, 3)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-4xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4" data-testid="props-diff-page-title">
          Props Diff Demo
        </h1>
        <p class="text-sm text-base-content/50 mb-6 text-center">
          Click a button, then compare the two payloads below: <strong>diff on</strong> sends only changed keys,
          <strong>diff off</strong> sends the full object every time.
        </p>

        <div class="flex flex-col gap-6" id="props-diff-demo-root" phx-hook="PropsDiffPayloadDisplay">
          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                LiveView controls
              </span>
              <div class="flex flex-wrap gap-3">
                <button
                  data-testid="props-diff-inc-a"
                  class="btn btn-sm btn-primary"
                  phx-click="inc_a"
                >
                  Increment A
                </button>
                <button
                  data-testid="props-diff-inc-b"
                  class="btn btn-sm btn-secondary"
                  phx-click="inc_b"
                >
                  Increment B
                </button>
                <button
                  data-testid="props-diff-inc-c"
                  class="btn btn-sm btn-accent"
                  phx-click="inc_c"
                >
                  Increment C
                </button>
              </div>
              <p class="text-xs text-base-content/50">
                Server state: A=<%= @a %>, B=<%= @b %>, C=<%= @c %>
              </p>
            </div>
          </section>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <section class="card bg-base-100 shadow-lg border border-base-300/50">
              <div class="card-body gap-4">
                <h2 class="text-lg font-semibold text-base-content">With diff (default)</h2>
                <p class="text-xs text-base-content/50">
                  Only changed props in payload after each update.
                </p>
                <.svelte
                  name="PropsDiffDemo"
                  props={%{a: @a, b: @b, c: @c, label: "diff on"}}
                  socket={@socket}
                />
              </div>
            </section>

            <section class="card bg-base-100 shadow-lg border border-base-300/50">
              <div class="card-body gap-4">
                <h2 class="text-lg font-semibold text-base-content">With diff off</h2>
                <p class="text-xs text-base-content/50">
                  Full props sent every time.
                </p>
                <.svelte
                  name="PropsDiffDemo"
                  props={%{a: @a, b: @b, c: @c, label: "diff off"}}
                  socket={@socket}
                  diff={false}
                />
              </div>
            </section>
          </div>

          <section class="card bg-base-100 shadow-lg border border-base-300/50" aria-label="Payload in DOM">
            <div class="card-body gap-2">
              <h2 class="text-lg font-semibold text-base-content">Payload in DOM (<code>data-props</code>)</h2>
              <p class="text-xs text-base-content/50 mb-2">
                After each update, the diff-on component receives only changed keys; the diff-off component receives the full object.
              </p>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <p class="text-xs font-medium text-base-content/70 mb-1">diff on (only changed keys)</p>
                  <pre id="payload-display-diff-on" class="bg-base-200 text-xs p-3 rounded-lg overflow-x-auto min-h-[4rem]" data-testid="payload-diff-on">—</pre>
                </div>
                <div>
                  <p class="text-xs font-medium text-base-content/70 mb-1">diff off (full object)</p>
                  <pre id="payload-display-diff-off" class="bg-base-200 text-xs p-3 rounded-lg overflow-x-auto min-h-[4rem]" data-testid="payload-diff-off">—</pre>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("inc_a", _params, socket) do
    {:noreply, assign(socket, :a, socket.assigns.a + 1)}
  end

  def handle_event("inc_b", _params, socket) do
    {:noreply, assign(socket, :b, socket.assigns.b + 1)}
  end

  def handle_event("inc_c", _params, socket) do
    {:noreply, assign(socket, :c, socket.assigns.c + 1)}
  end
end
