defmodule Mix.Tasks.LiveSvelte.InstallNpmDeps do
  import LiveSvelte.Logger

  @doc """
  Installs npm dependencies for LiveSvelte.
  """
  def run(_) do
    log_info("-- Installing npm dependencies...")

    "cd assets &&
    npm install --save-dev esbuild@^0.16.17 esbuild-svelte svelte svelte-preprocess esbuild-plugin-import-glob &&
    npm install --save ../deps/phoenix ../deps/phoenix_html ../deps/phoenix_live_view"
    |> String.to_charlist()
    |> :os.cmd()
    |> IO.puts()
  end
end
