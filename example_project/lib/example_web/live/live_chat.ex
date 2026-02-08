defmodule ExampleWeb.LiveChat do
  use ExampleWeb, :live_view
  use LiveSvelte.Components

  @topic "public"
  @event_new_message "new_message"

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-4 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Chat
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-sm">
        Enter your name to join; then send messages. Your name labels your bubbles.
      </p>

      <form :if={!@name} phx-submit="set_name" class="w-full max-w-md">
        <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden">
          <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
              Join
            </span>
            <div class="flex gap-2 flex-wrap">
              <!-- svelte-ignore a11y-autofocus -->
              <input
                type="text"
                placeholder="Your name"
                name="name"
                class="input input-bordered input-sm flex-1 min-w-0 bg-base-200/50 border-base-300"
                autofocus
                autocomplete="name"
                aria-label="Your name"
              />
              <button type="submit" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 shrink-0">
                Join
              </button>
            </div>
          </div>
        </div>
      </form>
      <div :if={@name} class="w-full flex justify-center">
        <.Chat
          messages={@messages}
          name={@name}
          socket={@socket}
        />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    ExampleWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, messages: [], name: nil)}
  end

  def handle_event("set_name", %{"name" => ""}, socket), do: {:noreply, socket}

  def handle_event("set_name", %{"name" => name}, socket),
    do: {:noreply, assign(socket, name: name)}

  def handle_event("send_message", payload, socket) do
    payload =
      payload
      |> Map.put(:name, socket.assigns.name)
      |> Map.put(:id, System.unique_integer([:positive]))

    ExampleWeb.Endpoint.broadcast(@topic, @event_new_message, payload)

    {:noreply, socket}
  end

  def handle_info(%{topic: @topic, event: @event_new_message, payload: payload}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [payload])}
  end
end
