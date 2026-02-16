defmodule ExampleWeb.MyLiveView do
  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:list, ["element", "element", "element"]) |> assign(:color, "white")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-1 border-green-400 p-5 rounded-md shadow-lg bg-slate-300">
      <h3 class="text-2xl font-light mb-5">LIVE VIEW</h3>
      <div class="flex flex-row justify-center items-center">
        <div class="flex flex-col justify-center items-center gap-4">
          <div>
            <div class="border-1 border-[var(--color-brand)] p-12 flex flex-row gap-5 justify-center items-center rounded-md shadow-lg bg-slate-200">
              Live Component
              <button class="btn bg-white text-black" phx-click="change_color_to_white">
                Change color to white
              </button>
              <button class="btn bg-red-500 text-white" phx-click="change_color_to_red">
                Change color to red
              </button>
              <button class="btn bg-[var(--color-brand)] text-white" phx-click="add_element">Add Element</button>
            </div>
          </div>
          <div class="flex flex-col gap-5">
            <%= for {item, index} <- Enum.with_index(@list) do %>
              <.svelte name="StaticTest" props={%{color: @color, index: index}} />
            <% end %>
          </div>
        </div>
        <div class="max-w-[30%]">
          LiveSvelte auto-detects the <code>index</code> key in props to generate
          stable, unique DOM IDs for each component in the loop.
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

  def handle_event("change_color_to_white", _params, socket) do
    {:noreply, assign(socket, color: "white")}
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
