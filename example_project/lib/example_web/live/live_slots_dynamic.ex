defmodule ExampleWeb.LiveSlotsDynamic do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Slots" socket={@socket}>
      <button phx-click="increase" class="bg-black text-white rounded p-2">
        Increment the number
      </button>
      <b><%= @number %></b>

      <:subtitle>
        <%= @number %>
      </:subtitle>
    </.svelte>
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, :number, 1)}
  end

  def handle_event("increase", _, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
