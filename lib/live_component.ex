defmodule LiveSvelte do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @moduledoc since: "0.1.0-rc4"

  use Phoenix.LiveComponent
  import Phoenix.HTML

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
      <div
        id={id(@name)}
        data-name={@name}
        data-props={json(@props)}
        data-inner-block={render_slot(@inner_block)}
        phx-update="ignore"
        phx-hook="SvelteComponent"
      >
        <%= raw(@ssr_render["html"]) %>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    # Making sure we only render once
    ssr_code =
      if not connected?(socket) do
        props = Map.get(assigns, :props, %{})

        slot =
          ~H"""
          <%= render_slot(@inner_block) %>
          """
          |> Phoenix.HTML.Safe.to_iodata()
          |> List.to_string()

        ssr_render(assigns.name, props, slot)
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ssr_render, ssr_code)

    {:ok, socket}
  end

  defp ssr_render(name, props, slots \\ nil)
  defp ssr_render(name, nil, slots), do: ssr_render(name, %{}, slots)

  defp ssr_render(name, props, slots),
    do: NodeJS.call!({"svelte/render", "render"}, [name, props, slots])

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
