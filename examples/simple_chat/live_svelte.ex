defmodule ExampleWeb.SimpleChatLive do
  use ExampleWeb, :live_view

  @topic "public"
  @event_new_message "new_message"

  def render(assigns) do
    ~H"""
    <LiveSvelte.svelte name="Chat" props={%{messages: @messages}}/>
    """
  end

  def mount(_params, _session, socket) do
    ExampleWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, messages: [])}
  end

  def handle_event("send_message", event, socket) do
    ExampleWeb.Endpoint.broadcast(@topic, @event_new_message, event)
    {:noreply, socket}
  end

  def handle_info(%{topic: @topic, event: @event_new_message, payload: payload}, socket) do
    payload = Map.put(payload, :id, System.unique_integer([:positive]))
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [payload])}
  end
end
