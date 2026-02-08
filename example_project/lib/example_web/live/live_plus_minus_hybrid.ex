defmodule ExampleWeb.LivePlusMinusHybrid do
  use ExampleWeb, :live_view
  use LiveSvelte.Components

  def render(assigns) do
    ~H"""
    <.svelte name="CounterHybrid" props={%{number: @number}} socket={@socket} />
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, %{number: 10})}
  end

  def handle_event("set_number", %{"value" => number}, socket) do
    {:noreply, assign(socket, :number, String.to_integer(number))}
  end
end
