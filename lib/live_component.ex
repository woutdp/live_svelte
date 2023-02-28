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
  attr(:rendered, :boolean, default: false)

  @doc """
  Renders a Svelte component on the server.
  """
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

  @impl true
  def update(assigns, socket) do
    # Making sure we only render once
    ssr_code =
      unless connected?(socket) do
        ssr_render(assigns.name, assigns[:props])
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:ssr_render, ssr_code)

    {:ok, socket}
  end

  defp ssr_render(name, nil), do: ssr_render(name, %{})
  defp ssr_render(name, props), do: NodeJS.call!({"svelte/render", "render"}, [name, props])

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
