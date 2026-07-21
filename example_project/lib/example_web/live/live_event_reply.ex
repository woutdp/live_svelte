defmodule ExampleWeb.LiveEventReply do
  @moduledoc """
  LiveView demo for the `useEventReply()` composable.
  Demonstrates request-response pattern: push event, await typed reply.
  """
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("compute", %{"value" => value}, socket) do
    input = value || 0
    {:reply, %{result: input * 2, input: input}, socket}
  end

  def handle_event("compute", _params, socket) do
    {:reply, %{result: 0, input: 0}, socket}
  end

  def render(assigns) do
    ~H"""
    <.demo_page title="Event Reply (useEventReply)" tag="h2" variant="compact">
      <:description>
        Push an event to Phoenix and receive a typed reply via promise.
      </:description>
      <.svelte name="EventReplyDemo" props={%{}} socket={@socket} />
    </.demo_page>
    """
  end
end
