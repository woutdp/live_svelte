defmodule LiveSvelte.SSR.NodeNotConfigured do
  @moduledoc false

  defexception message: """
                 NodeJS is not configured. Please add the following to your application.ex:
                 {NodeJS.Supervisor, [path: LiveSvelte.SSR.server_path(), pool_size: 4]},
               """
end

defmodule LiveSvelte.SSR do
  @moduledoc false

  @doc false
  def render(name, props, slots \\ nil)
  def render(name, nil, slots), do: render(name, %{}, slots)

  def render(name, props, slots) do
    try do
      NodeJS.call!({"server/server", "ssrRenderComponent"}, [name, props, slots])
    catch
      :exit, {:noproc, _} -> raise LiveSvelte.SSR.NodeNotConfigured
    end
  end

  def server_path() do
    {:ok, path} = :application.get_application()
    Application.app_dir(path, "/priv/static/assets")
  end
end
