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
    <div class="flex flex-col items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">Event Reply (useEventReply)</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Push an event to Phoenix and receive a typed reply via promise.
      </p>
      <.svelte name="EventReplyDemo" props={%{}} socket={@socket} />
    </div>
    """
  end
end
