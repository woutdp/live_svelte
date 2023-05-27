defmodule ExampleWeb.LiveExample4 do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="LogList" props={%{items: @items}} />
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)
    {:ok, assign(socket, :items, [])}
  end

  def handle_event("add_item", %{"body" => body}, socket) do
    {:noreply, assign(socket, :items, add_log(socket, body))}
  end

  def handle_info(:tick, socket) do
    datetime =
      DateTime.utc_now()
      |> DateTime.to_string()

    {:noreply, assign(socket, :items, add_log(socket, datetime))}
  end

  defp add_log(socket, body) do
    [%{id: System.unique_integer([:positive]), body: body} | socket.assigns.items]
  end
end
