defmodule ExampleWeb.LiveStaticColor do
  use ExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:list, ["element", "element", "element"]) |> assign(:color, "white")}
  end

  @impl true
  def render(assigns) do
    ~H"""
     <h1 class="text-center text-2xl font-light my-4">
          Static Color Demo
        </h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Passing dynamic props to a list of Svelte components from LiveView.
        </p>
    <div class="border-1 border-[var(--color-brand)] shadow-lg card p-5">
      <div class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">LiveView</div>
      <div class="flex flex-row my-4 justify-center items-center">
        <div class="flex flex-col justify-center items-center gap-4">
          <div>
            <div class="w-full border-1 border-gray-500 card card-lg p-5 flex flex-col gap-5 justify-center items-center">
              <div class="badge badge-outline badge-sm font-medium text-base-content/70 text-nowrap">LiveView Component</div>
            <div class="flex flex-col md:flex-row gap-4 items-center">
              <button class="btn bg-slate-50" phx-click="change_color_to_white">
                Change color to white
              </button>
              <button class="btn bg-red-500 text-white" phx-click="change_color_to_red">
                Change color to red
              </button>
              <button class="btn bg-[var(--color-brand)] text-white" phx-click="add_element">Add Element</button>
            </div>
              <div class="text-sm text-base-content/50 text-nowrap">Total elements: <span class="font-bold text-lg">{length(@list)}</span></div>
            </div>
          </div>
          <h3 class="my-4 text-base-content">Use LiveSvelte via a file based component (Static.svelte)</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            <%= for {item, index} <- Enum.with_index(@list) do %>
              <.svelte name="Static" props={%{color: @color, index: index}} />
            <% end %>
          </div>
          <div class="divider"></div>
          <h3 class="mb-4 text-base-content">Use LiveSvelte as a function via the (~V sigil) to render the Svelte component</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            <%= for {item, index} <- Enum.with_index(@list) do %>
              <.static_svelte_component color={@color} index={index} />
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

  def handle_event("change_color_to_white", _params, socket) do
    {:noreply, assign(socket, color: "white")}
  end

  def handle_event("change_color_to_red", _params, socket) do
    {:noreply, assign(socket, color: "red")}
  end

  def static_svelte_component(assigns) do
    ~V"""
      <script>
      /**
      * @type {{ color: string, index: number }}
      */
      let { color, index } = $props();
      const colorClass = $derived(
        color === "red" ? "text-red-500" : color === "blue" ? "text-blue-500" : "text-base-content/80"
      );
      const borderClass = $derived(
        color === "red" ? "border-red-500" : color === "blue" ? "border-blue-500" : "border-base-content/30"
      );
    </script>

    <div class="card card-xs bg-base-100 shadow-md border overflow-hidden {borderClass}">
      <div class="card-body gap-4 p-5">
        <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
          LiveSvelte (~V sigil)
        </span>
        <h3 class="font-semibold text-lg text-base-content">Svelte component {index}</h3>
        <p class="text-sm text-base-content/80">
          This svelte component will receive the color from the LiveView and display it.
        </p>
        <div
        class={colorClass}
        >
          <span class="font-medium italic uppercase" data-testid="static-color-svelte-value">{color}</span>
        </div>
      </div>
    </div>
    """
  end
end
