defmodule ExampleWeb.AdvancedChat do
  use ExampleWeb, :live_view

  @topic "public"
  @event_new_message "new_message"

  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-full w-full">
      <%= unless @name do %>
        <form phx-submit="set_name">
          <!-- svelte-ignore a11y-autofocus -->
          <input type="text" placeholder="Name" name="name" class="rounded" autofocus autocomplete="name" />
          <button class="py-2 px-4 bg-black text-white rounded">Join</button>
        </form>
      <% else %>
        <LiveSvelte.svelte
          name="AdvancedChat"
          props={%{messages: @messages, name: @name}}
          class="w-full h-full flex justify-center items-center"
        />
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    ExampleWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, messages: [], name: nil)}
  end

  def handle_event("set_name", %{"name" => ""}, socket), do: {:noreply, socket}
  def handle_event("set_name", %{"name" => name}, socket), do: {:noreply, assign(socket, name: name)}

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
