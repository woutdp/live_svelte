defmodule LiveSvelte.SSR.Deno do
  @moduledoc false
  @behaviour LiveSvelte.SSR

  def render(name, props, slots) do
    prepared_props = LiveSvelte.JSON.prepare(props)
    prepared_slots = LiveSvelte.JSON.prepare(slots)

    name_json = JSON.encode!(name)
    props_json = JSON.encode!(prepared_props)
    slots_json = JSON.encode!(prepared_slots)

    try do
      {:ok, body} =
        DenoRider.eval("globalThis.render(#{name_json}, #{props_json}, #{slots_json})")

      body
    catch
      :exit, {:noproc, _} ->
        raise %LiveSvelte.SSR.NotConfigured{
          message: """
          DenoRider is not configured. Please add the following to your application.ex:
          {DenoRider, [main_module_path: LiveSvelte.SSR.Deno.server_path() <> "/server.js"]},
          """
        }
    end
  end

  def server_path() do
    {:ok, path} = :application.get_application()
    Application.app_dir(path, "/priv/svelte")
  end
end
