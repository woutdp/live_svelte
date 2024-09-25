defmodule LiveSvelte.SSR.Bun do
  @moduledoc false
  @behaviour LiveSvelte.SSR

  def render(name, props, slots) do
    IO.inspect(name)
    IO.inspect(props)
    IO.inspect(slots)

    # 
    Bun.run(:default, ["{server_path()}/server.js"])
    |> IO.inspect()

    # try do
    #   NodeJS.call!({"server", "render"}, [name, props, slots], binary: true)
    # catch
    #   :exit, {:noproc, _} ->
    #     message = """
    #     NodeJS is not configured. Please add the following to your application.ex:
    #     {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
    #     """
    #
    #     raise %LiveSvelte.SSR.NotConfigured{message: message}
    # end
  end

  def server_path() do
    {:ok, path} = :application.get_application()
    Application.app_dir(path, "/priv/svelte")
  end
end
