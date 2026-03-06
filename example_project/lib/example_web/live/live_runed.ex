defmodule ExampleWeb.LiveRuned do
  use ExampleWeb, :live_view

  @items ~w(Elixir Erlang Phoenix LiveView Svelte Vue React Angular TypeScript
            JavaScript Rust Go Python Ruby Java Kotlin Swift Haskell Clojure Scala)

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       items: @items,
       matches: @items,
       last_size: %{width: nil, height: nil},
       combo_count: 0
     )}
  end

  def handle_event("search", %{"query" => query}, socket) do
    q = String.downcase(query)
    matches = Enum.filter(@items, &String.contains?(String.downcase(&1), q))
    {:noreply, assign(socket, matches: matches)}
  end

  def handle_event("resize", %{"width" => w, "height" => h}, socket) do
    {:noreply, assign(socket, last_size: %{width: round(w), height: round(h)})}
  end

  def handle_event("combo", _params, socket) do
    {:noreply, assign(socket, combo_count: socket.assigns.combo_count + 1)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4">Runed Utilities</h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Three utilities from <a href="https://runed.dev" class="link">runed</a>
          — Debounced, ElementSize, PressedKeys — each syncing client state back to Phoenix LiveView.
        </p>

        <div class="flex flex-col gap-8">
          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                RunedDemo
              </span>
              <.svelte
                name="RunedDemo"
                props={%{
                  items: @items,
                  matches: @matches,
                  lastSize: @last_size,
                  comboCount: @combo_count
                }}
                socket={@socket}
                ssr={false}
              />
            </div>
          </section>

          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                Server state
              </span>
              <p class="text-sm">
                Search matches: <strong data-testid="match-count">{length(@matches)}</strong>
              </p>
              <p class="text-sm">
                Last synced size:
                <strong data-testid="server-size">
                  <%= if @last_size.width do %>
                    {@last_size.width}×{@last_size.height}px
                  <% else %>
                    not yet synced
                  <% end %>
                </strong>
              </p>
              <p class="text-sm">
                Ctrl+Enter combos: <strong data-testid="combo-count">{@combo_count}</strong>
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
