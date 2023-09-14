defmodule LiveSvelte.SSR.NodeJS do
  @moduledoc false
  @behaviour LiveSvelte.SSR

  def render(name, props, slots) do
    try do
      NodeJS.call!({"server", "render"}, [name, props, slots])
    catch
      :exit, {:noproc, _} -> raise LiveSvelte.SSR.NodeNotConfigured
    end
  end

  def server_path() do
    {:ok, path} = :application.get_application()
    Application.app_dir(path, "/priv/svelte")
  end
end