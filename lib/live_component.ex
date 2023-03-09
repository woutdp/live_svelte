defmodule LiveSvelte do
  use Phoenix.LiveComponent
  import Phoenix.HTML

  alias LiveSvelte.Slots
  alias LiveSvelte.SSR

  attr(:props, :map, default: %{})
  attr(:name, :string)

  slot(:inner_block)

  @doc """
  Renders a Svelte component on the server.
  """
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- TODO: This can return things like <title> which should be in the head --%>
      <%!-- <script><%= raw(@ssr_render["head"]) %></script> --%>
      <style><%= raw(@ssr_render["css"]["code"]) %></style>
      <%= if not connected?(@socket) do %>
        <%= raw(@ssr_render["html"]) %>
      <% else %>
        <div
          id={id(@name)}
          data-name={@name}
          data-props={json(@props)}
          data-slots={Slots.base_encode_64(@slots) |> json}
          phx-update="ignore"
          phx-hook="SvelteComponent"
        >
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    slots =
      assigns
      |> Slots.rendered_slot_map()
      |> Slots.js_process()

    # Making sure we only render once
    ssr_code =
      if not connected?(socket) do
        SSR.render(assigns.name, Map.get(assigns, :props, %{}), slots)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:slots, slots)
      |> assign(:ssr_render, ssr_code)

    {:ok, socket}
  end

  defp json(props) do
    props
    |> Jason.encode()
    |> case do
      {:ok, encoded} -> encoded
      {:error, _} -> ""
    end
  end

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"
end
