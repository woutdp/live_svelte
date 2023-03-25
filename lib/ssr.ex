defmodule LiveSvelte.SSR.NodeNotConfigured do
  defexception message: """
                 NodeJS is not configured. Please add the following to your application.ex:
                 {NodeJS.Supervisor, [path: "#{File.cwd!()}/assets", pool_size: 4]},
               """
end

defmodule LiveSvelte.SSR do
  def render(name, props, slots \\ nil)
  def render(name, nil, slots), do: render(name, %{}, slots)

  def render(name, props, slots) do
    try do
      NodeJS.call!({"js/render", "render"}, [name, props, slots])
    catch
      :exit, {:noproc, _} -> raise LiveSvelte.SSR.NodeNotConfigured
    end
  end
end
