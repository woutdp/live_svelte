defmodule Mix.Tasks.LiveSvelte.ConfigurePhoenix do
  @moduledoc """
  Configures any necessary code changes inside Phoenix to make LiveSvelte work.
  """

  import LiveSvelte.Logger

  @watcher_regex ~r/watchers:\s\[(?!\s+node:)/
  @esbuild_regex ~r/(?<!# )esbuild: {.*}/
  @nodejs_regex ~r/children\s+=\s+\[(?!\s+\{NodeJS)/

  def run(_) do
    log_info("-- Configuring Phoenix...")

    try do
      configure_dev_config()
      configure_application()
    rescue
      err -> log_error(err.message)
    end

    Mix.Task.run("format")
  end

  defp configure_dev_config() do
    watcher = ~s"""
    node: ["build.js", "--watch", cd: Path.expand("../assets", __DIR__)],\
    """

    {path, file} = path_and_file("config/", "dev.exs")

    File.read!(path)
    |> insert(@watcher_regex, watcher, "'#{watcher}' in #{file}")
    |> comment(@esbuild_regex, "old esbuild watcher in #{file}")
    |> save(path)
  end

  defp configure_application() do
    nodeSupervisor = ~s"""
    {NodeJS.Supervisor, [path: LiveSvelte.SSR.server_path(), pool_size: 4]},\
    """

    {path, file} = path_and_file("lib/**/", "application.ex")

    File.read!(path)
    |> insert(@nodejs_regex, nodeSupervisor, "'#{nodeSupervisor}' in #{file}")
    |> save(path)
  end

  defp path_and_file(wildcard, filename) do
    {find_file("#{wildcard}#{filename}", filename), filename}
  end

  defp find_file(wildcard, file_name) do
    with [path] <- Path.wildcard(wildcard) do
      path
    else
      [] -> raise "Could not find #{file_name}"
      [_ | _] -> raise "Found multiple #{file_name} files"
    end
  end

  defp insert(source, regex, to_insert, name) do
    case Regex.run(regex, source, return: :index) do
      [{pos, len}] ->
        log_success("Inserted #{name}")
        insert_position(source, pos + len, to_insert)

      nil ->
        log_error("Could not insert #{name}, please do so yourself")
        source
    end
  end

  defp comment(source, regex, name) do
    case Regex.run(regex, source, return: :index) do
      [{pos, _len}] ->
        log_success("Commented out #{name}")
        insert_position(source, pos, "# ")

      nil ->
        log_warning("Could not comment out #{name}")
        source
    end
  end

  defp insert_position(source, position, to_insert) do
    {head, tail} = String.split_at(source, position)
    head <> to_insert <> tail
  end

  defp save(source, target_file), do: File.write!(target_file, source)
end
