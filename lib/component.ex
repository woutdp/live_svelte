defmodule LiveSvelte do
  use Phoenix.Component
  import Phoenix.HTML

  alias LiveSvelte.Slots
  alias LiveSvelte.SSR

  attr(:props, :map, default: %{})
  attr(:name, :string, required: true)

  slot(:inner_block)

  @doc """
  Renders a Svelte component on the server.
  """
  def render(assigns) do
    init = Map.get(assigns, :__changed__, nil) == nil

    slots =
      assigns
      |> Slots.rendered_slot_map()
      |> Slots.js_process()

    ssr_code =
      if init do
        SSR.render(assigns.name, Map.get(assigns, :props, %{}), slots)
      end

    assigns =
      assigns
      |> assign(:init, init)
      |> assign(:slots, slots)
      |> assign(:ssr_render, ssr_code)

    ~H"""
    <%!-- TODO: This can return things like <title> which should be in the head --%>
    <%!-- <script><%= raw(@ssr_render["head"]) %></script> --%>
    <%= if @init do %>
      <style><%= raw(@ssr_render["css"]["code"]) %></style>
      <%= raw(@ssr_render["html"]) %>
    <% else %>
      <div
        id={id(@name)}
        data-name={@name}
        data-props={json(@props)}
        data-slots={Slots.base_encode_64(@slots) |> json}
        phx-update="ignore"
        phx-hook="SvelteHook"
      >
      </div>
    <% end %>
    """
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
