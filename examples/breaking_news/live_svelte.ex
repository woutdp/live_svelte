defmodule Example.LiveSvelte do
  use ExampleWeb, :live_view

  @initial_news [
    %{body: "World peace has been achieved!", id: 1},
    %{body: "Some other crazy stuff happened", id: 2},
    %{body: "Car crash in city center", id: 3}
  ]

  def render(assigns) do
    ~H"""
    <.live_component module={LiveSvelte} id="live-svelte" name="BreakingNews" props={%{news: @news}} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :news, @initial_news)}
  end

  def handle_event("remove_news_item", %{"id" => id} = params, socket) do
    socket = assign(socket, :news, Enum.reject(socket.assigns.news, fn item -> item.id == id end))
    {:noreply, socket}
  end

  def handle_event("add_news_item", %{"body" => item} = params, socket) do
    new_item = %{body: item, id: get_id()}
    {:noreply, assign(socket, :news, socket.assigns.news ++ [new_item])}
  end

  def get_id(), do: System.unique_integer([:positive])
end
