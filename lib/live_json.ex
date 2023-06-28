defmodule LiveSvelte.LiveJson do
  use Phoenix.Component

  attr(
    :live_json_props,
    :map,
    default: %{},
    doc: "LiveJSON props to pass to the svelte component"
  )

  slot(:inner_block)

  def live_json(assigns) do
    ~H"""
    <%= if @live_json_props != %{} do %>
      <div id={id("lj")} phx-hook="LiveJSON" />
    <% end %>
    <%= render_slot(@inner_block) %>
    """
  end

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"
end
