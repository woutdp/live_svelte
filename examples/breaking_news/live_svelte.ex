defmodule ExampleWeb.BreakingNewsLive do
  use ExampleWeb, :live_view

  @initial_news [
    %{id: 1, body: "Giant Pink Elephant Sighted Downtown"},
    %{id: 2, body: "Local Cat Becomes Mayor of Small Town"},
    %{id: 3, body: "Scientists Discover New Flavor of Ice Cream"},
    %{id: 4, body: "World's Largest Pizza Baked in Local Pizzeria, Still Not Big Enough for Customers"},
    %{id: 5, body: "Clown Epidemic Sweeps Through Town, Everyone Laughs Until They Realize the Clowns Aren't Joking"},
  ]

  def render(assigns) do
    ~H"""
    <LiveSvelte.svelte name="BreakingNews" props={%{news: @news}} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :news, @initial_news)}
  end

  def handle_event("remove_news_item", %{"id" => id}, socket) do
    updated_news = Enum.reject(socket.assigns.news, fn item -> item.id == id end)
    {:noreply, assign(socket, :news, updated_news)}
  end

  def handle_event("add_news_item", %{"body" => body}, socket) do
    new_item = %{id: System.unique_integer([:positive]), body: body}
    updated_news = socket.assigns.news ++ [new_item]
    {:noreply, assign(socket, :news, updated_news)}
  end
end
