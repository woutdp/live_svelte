defmodule ExampleWeb.LiveIdListDiff do
  @moduledoc """
  Demo for Tier 3 ID-based list diffing: Jsonpatch uses :id to match items by identity,
  so inserting or deleting from a list with :id fields produces minimal patch operations
  (1 add/remove) instead of replacing every shifted item.
  """
  use ExampleWeb, :live_view

  @initial_items [
    %{id: 1, name: "Alice"},
    %{id: 2, name: "Bob"},
    %{id: 3, name: "Carol"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:items, @initial_items)
     |> assign(:next_id, 4)}
  end

  def render(assigns) do
    ~H"""
    <.demo_page title="ID-Based List Diffing Demo" title_testid="id-list-diff-title">
      <:description>
        Inserts and deletes produce minimal JSON Patch ops because list items carry an
        <code>:id</code>
        field.
      </:description>

      <.demo_card label="LiveView controls">
        <div class="flex flex-wrap gap-3">
          <button data-testid="insert-item" class="btn btn-sm btn-primary" phx-click="insert_item">
            Insert Item
          </button>
          <button data-testid="delete-first" class="btn btn-sm btn-error" phx-click="delete_first">
            Delete First
          </button>
          <button
            data-testid="move-last"
            class="btn btn-sm btn-secondary"
            phx-click="move_last_to_top"
          >
            Move Last to Top
          </button>
        </div>
        <p class="text-xs text-base-content/50">
          Item count: {length(@items)}
        </p>
      </.demo_card>

      <.svelte name="IdListDiff" props={%{items: @items}} socket={@socket} />
    </.demo_page>
    """
  end

  def handle_event("insert_item", _params, socket) do
    new_item = %{id: socket.assigns.next_id, name: "Item #{socket.assigns.next_id}"}

    {:noreply,
     socket
     |> assign(:items, [new_item | socket.assigns.items])
     |> assign(:next_id, socket.assigns.next_id + 1)}
  end

  def handle_event("delete_first", _params, socket) do
    case socket.assigns.items do
      [] -> {:noreply, socket}
      [_ | rest] -> {:noreply, assign(socket, :items, rest)}
    end
  end

  def handle_event("move_last_to_top", _params, socket) do
    case socket.assigns.items do
      [] ->
        {:noreply, socket}

      [_] ->
        {:noreply, socket}

      items ->
        last = List.last(items)
        rest = Enum.take(items, length(items) - 1)
        {:noreply, assign(socket, :items, [last | rest])}
    end
  end
end
