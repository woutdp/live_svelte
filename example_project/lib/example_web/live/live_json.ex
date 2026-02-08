defmodule ExampleWeb.LiveJson do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Live JSON
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Large payloads are patched over the wire. Compare SSR vs no-SSR and watch the WebSocket traffic when removing elements.
      </p>

      <div class="flex flex-wrap justify-center gap-8 w-full max-w-4xl">
        <section class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-sm">
          <div class="card-body gap-2 p-4">
            <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
              SSR
            </span>
            <.svelte id="live-json-ssr" name="LiveJson" live_json_props={%{big_data_set: @ljbig_data_set}} socket={@socket} />
          </div>
        </section>
        <section class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-sm">
          <div class="card-body gap-2 p-4">
            <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
              No SSR
            </span>
            <.svelte id="live-json-no-ssr" name="LiveJson" live_json_props={%{big_data_set: @ljbig_data_set}} ssr={false} />
          </div>
        </section>
      </div>
    </div>
    """
  end

  def mount(_session, _params, socket) do
    data =
      for i <- 1..100_000,
          into: %{} do
        {i, Enum.random(1..1_000_000_000)}
      end

    {:ok, LiveJson.initialize(socket, "big_data_set", data)}
  end

  def handle_event("remove_element", _values, socket) do
    random_key =
      socket.assigns.ljbig_data_set
      |> Map.keys()
      |> Enum.random()

    {
      :noreply,
      LiveJson.push_patch(
        socket,
        "big_data_set",
        Map.delete(socket.assigns.ljbig_data_set, random_key)
      )
    }
  end
end
