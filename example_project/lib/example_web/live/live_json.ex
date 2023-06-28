defmodule ExampleWeb.LiveJson do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex gap-10">
      <div>
        SSR:
        <.svelte name="LiveJson" live_json_props={%{big_data_set: @ljbig_data_set}} />
      </div>
      <div>
        No SSR:
        <.svelte name="LiveJson" live_json_props={%{big_data_set: @ljbig_data_set}} ssr={false} />
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
