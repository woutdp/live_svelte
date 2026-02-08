defmodule ExampleWeb.LiveStaticColor do
  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:list, ["element", "element", "element"]) |> assign(:color, "white")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-4 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Static color
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Svelte component receives color from LiveView; list re-renders on server.
      </p>
      <div class="w-full max-w-4xl rounded-2xl border border-base-300/50 bg-gradient-to-br from-base-100 to-base-200/40 shadow-xl shadow-base-300/10 overflow-hidden">
        <div class="px-4 pt-4 pb-1 border-b border-base-300/30 bg-base-200/20">
          <span class="badge badge-outline badge-sm font-medium text-base-content/60 border-base-300/50">LiveView + LiveSvelte</span>
        </div>
        <div class="p-6 flex flex-row flex-wrap justify-center items-stretch gap-6">
          <div class="flex flex-row justify-center items-center">
            <.svelte name="Static" props={%{color: @color}} />
          </div>
          <div class="flex flex-col justify-center items-center gap-4">
            <div>
              <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden">
                <div class="card-body gap-4 p-5 flex flex-row flex-wrap gap-3 justify-center items-center">
                  <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
                    LiveView
                  </span>
                  <button class="btn btn-sm bg-blue-500 text-white border-0" phx-click="change_color_to_blue">
                    Change color to blue
                  </button>
                  <button class="btn btn-sm bg-red-500 text-white border-0" phx-click="change_color_to_red">
                    Change color to red
                  </button>
                  <button class="btn btn-sm btn-outline border-base-300" phx-click="add_element">Add Element</button>
                </div>
              </div>
            </div>

            <%= for {item, index} <- Enum.with_index(@list) do %>
              <div class="card bg-base-200/50 border border-base-300/50 rounded-lg flex flex-row justify-center items-center p-4 min-w-[8rem]">
                <div :if={@color == "red"} class="text-red-500 font-medium">red</div>
                <div :if={@color == "blue"} class="text-blue-500 font-medium">blue</div>
                <div :if={@color == "white"} class="text-base-content/70 font-medium">white</div>
              </div>
            <% end %>
          </div>
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
