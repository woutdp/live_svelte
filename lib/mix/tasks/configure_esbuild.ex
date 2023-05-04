defmodule Mix.Tasks.LiveSvelte.ConfigureEsbuild do
  @moduledoc """
  Creates Javascript files to be used by esbuild. Necessary for LiveSvelte to work.
  """

  import LiveSvelte.Logger

  def run(_) do
    log_info("-- Configuring esbuild...")

    Mix.Project.deps_paths(depth: 1)
    |> Map.fetch!(:live_svelte)
    |> Path.join("assets/copy/**/*.{js,json}")
    |> Path.wildcard()
    |> Enum.each(fn full_path ->
      [_beginning, relative_path] = String.split(full_path, "copy", parts: 2)

      Mix.Generator.copy_file(full_path, "assets" <> relative_path)
    end)

    Mix.Generator.create_directory("assets/svelte")
  end
end
