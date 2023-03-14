defmodule Mix.Tasks.LiveSvelte.ConfigureEsbuild do
  @moduledoc """
  Creates Javascript files to be used by esbuild. Necessary for LiveSvelte to work.
  """

  import LiveSvelte.Logger

  def run(_) do
    log_info("-- Configuring esbuild...")

    Mix.Project.deps_paths(depth: 1)
    |> Map.fetch!(:live_svelte)
    |> Path.join("assets/copy/**/*{.js}")
    |> Path.wildcard()
    |> Enum.each(fn file ->
      split = Path.split(file)
      assets_index = Enum.find_index(split, fn item -> item == "assets" end)

      path =
        split
        |> Stream.with_index()
        |> Stream.reject(fn {_item, i} -> assets_index > i end)
        |> Enum.map(&elem(&1, 0))
        |> Enum.reject(&(&1 == "copy"))
        |> Path.join()

      Mix.Generator.copy_file(file, path)
    end)

    Mix.Generator.create_directory("assets/svelte")
  end
end
