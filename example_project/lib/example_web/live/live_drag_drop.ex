defmodule ExampleWeb.LiveDragDrop do
  use ExampleWeb, :live_view

  @initial_items [
    %{id: 1, name: "Design mockups"},
    %{id: 2, name: "Set up database"},
    %{id: 3, name: "Write API endpoints"},
    %{id: 4, name: "Build frontend"},
    %{id: 5, name: "Write tests"},
    %{id: 6, name: "Deploy to production"}
  ]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, items: @initial_items)}
  end

  def handle_event("reorder", %{"ids" => ids}, socket) do
    ordered =
      Enum.map(ids, fn id ->
        Enum.find(socket.assigns.items, &(&1.id == id))
      end)

    {:noreply, assign(socket, items: ordered)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4">Drag & Drop Demo</h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Reorder tasks with drag and drop. The new order is synced to the server via pushEvent.
        </p>

        <div class="flex flex-col gap-8">
          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                LiveSvelte
              </span>
              <.svelte name="DragDrop" props={%{items: @items}} socket={@socket} />
            </div>
          </section>

          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                Server order
              </span>
              <ol data-testid="server-order-list" class="list-decimal list-inside space-y-1 text-sm">
                <li :for={item <- @items} data-testid="server-order-item">{item.name}</li>
              </ol>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
