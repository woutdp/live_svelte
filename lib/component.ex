defmodule LiveSvelte do
  use Phoenix.Component

  attr(:props, :map, default: %{})
  attr(:name, :string)

  def render(%{name: name, props: props, __changed__: changed} = assigns) do
    assigns |> IO.inspect()

    assigns =
      assigns
      |> assign(:ssr_render, ssr_render(name, props, changed))
      |> assign(:id, id(assigns.name))

    ~H"""
    <.live_component
      module={LiveSvelte.LiveComponent}
      id={@id}
      name={@name}
      props={@props}
      ssr_render={@ssr_render}
    />
    """
  end

  def ssr_render(name, props, nil) do
    "SSR RENDERING" |> IO.inspect()
    NodeJS.call!({"svelte/render", "render"}, [name, props])
  end

  def ssr_render(_name, _props, _changed) do
    "NOT SSR RENDERING" |> IO.inspect()
    %{"html" => "", "css" => %{"code" => ""}, "head" => ""}
  end

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"
end
