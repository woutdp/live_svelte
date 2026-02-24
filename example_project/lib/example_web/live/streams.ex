defmodule ExampleWeb.Streams do
  @moduledoc """
  Demo for Phoenix Streams integration: stream items are sent to a Svelte component
  via data-streams-diff patches with correct insert, delete, and reset behavior.
  """
  use ExampleWeb, :live_view

  @initial_items [
    %{id: 1, name: "Item 1", description: "First item"},
    %{id: 2, name: "Item 2", description: "Second item"},
    %{id: 3, name: "Item 3", description: "Third item"}
  ]

  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_configure(:items, dom_id: fn item -> "items-#{item.id}" end)
      |> stream(:items, @initial_items)
      |> assign(:next_id, 4)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4" data-testid="streams-page-title">
          Phoenix Streams Demo
        </h1>
        <p class="text-sm text-base-content/50 mb-6 text-center">
          Stream items are sent via <code>data-streams-diff</code> patches to the Svelte component.
        </p>

        <.svelte name="StreamDemo" items={@streams.items} socket={@socket} />
      </div>
    </div>
    """
  end

  def handle_event("add_item", %{"name" => name, "description" => description}, socket) do
    new_item = %{
      id: socket.assigns.next_id,
      name: name,
      description: description
    }

    socket =
      socket
      |> stream_insert(:items, new_item)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def handle_event("remove_item", %{"id" => id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :items, "items-#{id}")}
  end

  def handle_event("update_item", %{"id" => id}, socket) do
    updated = %{id: id, name: "Updated #{id}", description: "Updated description"}
    {:noreply, stream_insert(socket, :items, updated)}
  end

  def handle_event("clear_stream", _params, socket) do
    {:noreply, stream(socket, :items, [], reset: true)}
  end

  def handle_event("reset_stream", _params, socket) do
    socket =
      socket
      |> stream(:items, @initial_items, at: -1, reset: true)
      |> assign(:next_id, 4)

    {:noreply, socket}
  end

  def handle_event("reset_stream_at_0", _params, socket) do
    socket =
      socket
      |> stream(:items, @initial_items, at: 0, reset: true)
      |> assign(:next_id, 4)

    {:noreply, socket}
  end
end
