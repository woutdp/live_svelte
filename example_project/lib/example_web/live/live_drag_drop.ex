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
    <.demo_page title="Drag & Drop Demo">
      <:description>
        Reorder tasks with drag and drop. The new order is synced to the server via pushEvent.
      </:description>

      <.demo_card label="LiveSvelte">
        <.svelte name="DragDrop" props={%{items: @items}} socket={@socket} />
      </.demo_card>

      <.demo_card label="Server order">
        <ol data-testid="server-order-list" class="list-decimal list-inside space-y-1 text-sm">
          <li :for={item <- @items} data-testid="server-order-item">{item.name}</li>
        </ol>
      </.demo_card>
    </.demo_page>
    """
  end
end
