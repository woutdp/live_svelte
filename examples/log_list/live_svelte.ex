defmodule ExamplesWeb.LogListLive do
  use ExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <LiveSvelte.svelte name="LogList" props={%{items: @items}} />
    """
  end

  def handle_event("add_item", %{"name" => name}, socket) do
    socket =
      socket
      |> assign(:items, [%{id: System.unique_integer([:positive]), name: name} | socket.assigns.items])

    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, assign(socket, :items, [])}
  end

  def handle_info(:tick, socket) do
    datetime =
      DateTime.utc_now()
      |> DateTime.to_string()

    socket =
     socket
     |> assign(:items, [%{id: System.unique_integer([:positive]), name: datetime} | socket.assigns.items])

    {:noreply, socket}
  end
end
