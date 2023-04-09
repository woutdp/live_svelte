defmodule LiveSvelte.SSR.NodeNotConfigured do
  @moduledoc false

  defexception message: """
                 NodeJS is not configured. Please add the following to your application.ex:
                 {NodeJS.Supervisor, [path: "#{File.cwd!()}/assets", pool_size: 4]},
               """
end

defmodule LiveSvelte.SSR do
  @moduledoc false

  @doc false
  def render(name, props, slots \\ nil)
  def render(name, nil, slots), do: render(name, %{}, slots)

  def render(name, props, slots) do
    try do
      server_path =
        Application.get_env(:live_svelte, :otp_name)
        |> Application.app_dir("/priv/static/assets/server/server.js")

      NodeJS.call!({"server/server", "ssrRenderComponent"}, [server_path, name, props, slots])
    catch
      :exit, {:noproc, _} -> raise LiveSvelte.SSR.NodeNotConfigured
    end
  end
end
