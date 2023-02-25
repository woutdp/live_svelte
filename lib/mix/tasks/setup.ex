defmodule Mix.Tasks.LiveSvelte.Setup do
  @moduledoc """
  Runs all setup tasks for LiveSvelte.
  """

  import LiveSvelte.Logger

  def run(_) do
    [
      "install_npm_deps",
      "configure_phoenix",
      "configure_esbuild"
    ]
    |> Enum.map(&Task.async(fn -> Mix.Task.run("live_svelte." <> &1) end))
    |> Enum.map(&Task.await(&1, :infinity))

    log_success("live_svelte setup finished.")
  end
end
