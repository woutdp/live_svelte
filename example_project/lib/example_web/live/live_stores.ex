defmodule ExampleWeb.LiveStores do
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, server_value: nil, sync_count: 0)}
  end

  def handle_event("sync_store", %{"value" => value}, socket) do
    {:noreply, assign(socket, server_value: value, sync_count: socket.assigns.sync_count + 1)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4">Svelte Stores</h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Two instances of the same component share a single
          <code class="font-mono">writable</code>
          store. Clicking +1 in either card instantly updates both — no props, no events, no server round-trip.
        </p>

        <div class="flex flex-col gap-8">
          <div class="grid grid-cols-2 gap-4">
            <div data-testid="store-instance-1">
              <.svelte
                name="StoreCounter"
                props={%{label: "Instance A"}}
                socket={@socket}
              />
            </div>
            <div data-testid="store-instance-2">
              <.svelte
                name="StoreCounter"
                props={%{label: "Instance B"}}
                socket={@socket}
              />
            </div>
          </div>

          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                Server state
              </span>
              <p class="text-sm">
                Last synced value:
                <strong data-testid="server-value">
                  <%= if @server_value != nil do %>
                    {@server_value}
                  <% else %>
                    not yet synced
                  <% end %>
                </strong>
              </p>
              <p class="text-sm">
                Sync count: <strong data-testid="sync-count">{@sync_count}</strong>
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
