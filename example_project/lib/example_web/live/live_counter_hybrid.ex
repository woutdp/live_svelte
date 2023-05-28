defmodule ExampleWeb.LiveExample3 do
  use ExampleWeb, :live_view
  use LiveSvelte.Components

  def render(assigns) do
    ~H"""
    <h1 class="flex justify-center mb-10 font-bold">Hybrid: LiveView + Svelte</h1>

    <.CounterHybrid number={@number} />
    """
  end

  def mount(_session, _params, socket) do
    {:ok, assign(socket, %{number: 10})}
  end

  def handle_event("set_number", %{"value" => number}, socket) do
    {:noreply, assign(socket, :number, String.to_integer(number))}
  end
end
