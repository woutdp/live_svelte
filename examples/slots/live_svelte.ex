defmodule ExamplesWeb.SlotsLive do
  use ExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <LiveSvelte.svelte name="Slots">
      This is the default inner_block
      <:the-slot-name>
        It's working
        <%= for item <- @items do %>
          <div class="flex justify-center items-center">
            <b><%= item.name %></b>
          </div>
        <% end %>
      </:the-slot-name>
    </LiveSvelte.svelte>
    """
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
