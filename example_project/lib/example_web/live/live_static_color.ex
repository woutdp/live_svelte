defmodule ExampleWeb.LiveStaticColor do
  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:list, ["element", "element", "element"]) |> assign(:color, "white")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-4 border-green-400 p-5">
      <div>LIVEVIEW</div>
      <div class="flex flex-row">
        <div class="flex flex-row justify-center items-center">
          <.svelte name="Static" props={%{color: @color}} />
        </div>
        <div class="flex flex-col justify-center items-center">
          <div>
            <div class="border-4 border-purple-400 p-12 flex flex-row gap-5 justify-center items-center">
              Live Component
              <button class="btn btn-primary" phx-click="change_color_to_blue">
                Change color to blue
              </button>
              <button class="btn btn-primary" phx-click="change_color_to_red">
                Change color to red
              </button>
              <button class="btn btn-primary" phx-click="add_element">Add Element</button>
            </div>
          </div>

          <%= for {item, index} <- Enum.with_index(@list) do %>
            <div class="border-4 border-purple-400 flex-row justify-center items-center p-4">
              <div :if={@color == "red"} class="text-red-400">red</div>
              <div :if={@color == "blue"} class="text-blue-400">blue</div>
              <div :if={@color == "white"} class="text-white-400">white</div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Using a case statement is often cleaner than multiple defs
    case params do
      %{"color" => color} ->
        {:noreply, assign(socket, :color, color)}

      _ ->
        {:noreply, assign(socket, :color, "white")}
    end
  end

  @impl true
  def handle_event("add_element", _params, socket) do
    # Appending to the list
    new_list = socket.assigns.list ++ ["element"]
    {:noreply, assign(socket, list: new_list)}
  end

  def handle_event("change_color_to_blue", _params, socket) do
    {:noreply, assign(socket, color: "blue")}
  end

  def handle_event("change_color_to_red", _params, socket) do
    {:noreply, assign(socket, color: "red")}
  end

  def static_svelte_component(assigns) do
    ~V"""
    <script>
    let { color } = $props();
    </script>


    <div
    class="flex flex-col justify-center items-center gap-4 w-100 border-4 border-red-400"
    >
    <div class="text-red-400 font-bold p-5 text-[20px]">Svelte component</div>

    <div class="text-red-400 font-bold p-5 text-[20px] flex flex-col gap-3">
        This svelte component will disappear whenever the "Add Element" button is pressed.
    </div>
    <div class={`text-${color}-400`}>
        {color}
    </div>
    </div>
    """
  end
end
