defmodule LiveSvelte do
  use Phoenix.LiveComponent
  import Phoenix.HTML

  attr(:props, :map, default: %{})
  attr(:name, :string)
  attr(:rendered, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <div>
      <%!-- TODO: This can return things like <title> which should be in the head --%>
      <%!-- <script><%= raw(@ssr_render["head"]) %></script> --%>
      <style><%= raw(@ssr_render["css"]["code"]) %></style>
      <div
        id={id(@name)}
        data-name={@name}
        data-props={json(@props)}
        phx-update="ignore"
        phx-hook="SvelteComponent"
      >
        <%= raw(@ssr_render["html"]) %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    # Maybe something like this?
    # socket = if not Map.get(assigns, :rendered, false) do
    #   send self(), {:rendered, true}
    # end

    socket =
      socket
      |> assign(assigns)
      # TODO: Only render once
      |> assign(:ssr_render, ssr_render(assigns.name, assigns.props))

    {:ok, socket}
  end

  def ssr_render(name, props) do
    NodeJS.call!({"svelte/render", "render"}, [name, props])
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
