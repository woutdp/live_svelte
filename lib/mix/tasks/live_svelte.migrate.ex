defmodule Mix.Tasks.LiveSvelte.Migrate do
  @moduledoc """
  Migrates LiveSvelte SSR adapter between Node.js and Deno.

  ## Options

    * `--ssr-node-to-deno` - Migrate from Node.js SSR to Deno SSR (via deno_rider)
    * `--ssr-deno-to-node` - Migrate from Deno SSR back to Node.js SSR

  Both flags update `prod.exs`, `application.ex`, `assets/js/server.js`, and
  `mix.exs` deps. You will be asked before any dependency is removed.

  ## Examples

      mix live_svelte.migrate --ssr-node-to-deno
      mix live_svelte.migrate --ssr-deno-to-node

  """

  Code.ensure_compiled(Igniter)

  import Mix.Tasks.PhoenixVite.Install.Helper

  with_igniter do
    use Igniter.Mix.Task

    alias Igniter.Project.Config
    alias Igniter.Project.Deps

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        schema: [ssr_node_to_deno: :boolean, ssr_deno_to_node: :boolean],
        aliases: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      node_to_deno? = Keyword.get(igniter.args.options, :ssr_node_to_deno, false)
      deno_to_node? = Keyword.get(igniter.args.options, :ssr_deno_to_node, false)

      cond do
        node_to_deno? and deno_to_node? ->
          Mix.shell().error("Cannot specify both --ssr-node-to-deno and --ssr-deno-to-node")
          igniter

        node_to_deno? ->
          migrate_node_to_deno(igniter)

        deno_to_node? ->
          migrate_deno_to_node(igniter)

        true ->
          Mix.shell().error("""
          Please specify a migration direction:
            --ssr-node-to-deno   migrate from Node.js SSR to Deno SSR
            --ssr-deno-to-node   migrate from Deno SSR to Node.js SSR
          """)

          igniter
      end
    end

    defp migrate_node_to_deno(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter) |> to_string()
      app_file = "lib/#{app_name}/application.ex"

      replace_supervisor? =
        Mix.shell().yes?(
          "Replace the NodeJS supervisor with Deno in application.ex? " <>
            "(answer no if your project uses Node.js for other things)"
        )

      igniter
      |> Deps.add_dep({:deno_rider, "~> 0.2"})
      |> Config.configure(
        "prod.exs",
        :live_svelte,
        [:ssr_module],
        {:code, Sourceror.parse_string!("LiveSvelte.SSR.Deno")}
      )
      |> then(fn ig ->
        if replace_supervisor?,
          do: update_application_supervisor(ig, app_file, :node_to_deno),
          else: add_deno_supervisor(ig, app_file)
      end)
      |> update_server_js(:node_to_deno)
      |> Igniter.add_notice("Run `mix deps.get` to fetch the new dependencies.")
    end

    defp migrate_deno_to_node(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter) |> to_string()
      app_file = "lib/#{app_name}/application.ex"

      remove_deno_rider? =
        Mix.shell().yes?(
          "Remove the :deno_rider dependency? (no longer needed when using Node.js SSR)"
        )

      igniter
      |> then(fn ig ->
        if remove_deno_rider?, do: Deps.remove_dep(ig, :deno_rider), else: ig
      end)
      |> Config.configure(
        "prod.exs",
        :live_svelte,
        [:ssr_module],
        {:code, Sourceror.parse_string!("LiveSvelte.SSR.NodeJS")}
      )
      |> update_application_supervisor(app_file, :deno_to_node)
      |> update_server_js(:deno_to_node)
      |> Igniter.add_notice("Run `mix deps.get` to fetch the new dependencies.")
    end

    # Adds a Deno supervisor block alongside an existing NodeJS one.
    # Used when the user keeps Node.js for other purposes.
    defp add_deno_supervisor(igniter, app_file) do
      Igniter.update_file(igniter, app_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "DenoRider") do
            content
          else
            deno_entry =
              ~s|[{DenoRider, [main_module_path: LiveSvelte.SSR.Deno.server_path() <> "/server.js"]}]|

            String.replace(
              content,
              ~r/([ \t]*)((?:node_js_children|deno_rider_children) = \[)/,
              "\\1deno_rider_children =\n" <>
                "\\1  if Application.get_env(:live_svelte, :ssr_module, nil) == LiveSvelte.SSR.Deno do\n" <>
                "\\1    #{deno_entry}\n" <>
                "\\1  else\n" <>
                "\\1    []\n" <>
                "\\1  end\n\n" <>
                "\\1\\2",
              global: false
            )
          end
        end)
      end)
    end

    defp update_application_supervisor(igniter, app_file, direction) do
      Igniter.update_file(igniter, app_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          case direction do
            :node_to_deno -> supervisor_node_to_deno(content)
            :deno_to_node -> supervisor_deno_to_node(content)
          end
        end)
      end)
    end

    defp supervisor_node_to_deno(content) do
      if String.contains?(content, "NodeJS.Supervisor") do
        content
        |> String.replace(
          "== LiveSvelte.SSR.NodeJS do",
          "== LiveSvelte.SSR.Deno do"
        )
        |> String.replace(
          "[{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}]",
          ~s|[{DenoRider, [main_module_path: LiveSvelte.SSR.Deno.server_path() <> "/server.js"]}]|
        )
        |> String.replace("node_js_children", "deno_rider_children")
      else
        content
      end
    end

    defp supervisor_deno_to_node(content) do
      if String.contains?(content, "DenoRider") do
        content
        |> String.replace(
          "== LiveSvelte.SSR.Deno do",
          "== LiveSvelte.SSR.NodeJS do"
        )
        |> String.replace(
          ~s|[{DenoRider, [main_module_path: LiveSvelte.SSR.Deno.server_path() <> "/server.js"]}]|,
          "[{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}]"
        )
        |> String.replace("deno_rider_children", "node_js_children")
      else
        content
      end
    end

    defp update_server_js(igniter, direction) do
      Igniter.update_file(igniter, "assets/js/server.js", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          case direction do
            :node_to_deno ->
              if String.contains?(content, "globalThis.render") do
                content
              else
                String.trim_trailing(content) <> "\nglobalThis.render = render\n"
              end

            :deno_to_node ->
              content
              |> String.replace("\nglobalThis.render = render\n", "\n")
              |> String.replace("globalThis.render = render\n", "")
              |> String.replace("\nglobalThis.render = render", "")
          end
        end)
      end)
    end
  else
    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'live_svelte.migrate' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
