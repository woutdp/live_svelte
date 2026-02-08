defmodule LiveSvelte.LiveJson do
  use Phoenix.Component

  attr(
    :live_json_props,
    :map,
    default: %{},
    doc: "LiveJSON props to pass to the svelte component"
  )

  attr(
    :svelte_id,
    :string,
    required: true,
    doc: "Stable DOM id from the parent svelte component"
  )

  slot(:inner_block)

  def live_json(assigns) do
    ~H"""
    <%= if @live_json_props != %{} do %>
      <div id={"lj-#{@svelte_id}"} phx-hook="LiveJSON" />
    <% end %>
    <%= render_slot(@inner_block) %>
    """
  end
end
