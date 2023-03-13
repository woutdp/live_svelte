defmodule LiveSvelte.SSR do
  def render(name, props, slots \\ nil)
  def render(name, nil, slots), do: render(name, %{}, slots)

  def render(name, props, slots),
    do: NodeJS.call!({"js/render", "render"}, [name, props, slots])
end
