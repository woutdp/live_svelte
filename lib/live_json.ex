defmodule LiveSvelte.LiveJson do
  use Phoenix.Component

  attr(
    :live_json_props,
    :map,
    default: %{},
    doc: "LiveJson props to pass to the Svelte component"
  )

  slot(:inner_block)

  def live_json(assigns) do
    ~H"""
    <%= if @live_json_props != %{} do %>
      <div id="lj" phx-hook="LiveJSON">
        <%= render_slot(@inner_block) %>
      </div>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end
end
