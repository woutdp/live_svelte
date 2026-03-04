defmodule Mix.Tasks.LiveSvelte.Install do
  @moduledoc """
  Installer for LiveSvelte with Vite.

  This task first installs Vite using the PhoenixVite installer,
  then configures the project for LiveSvelte.

  ## Options

    * `--bun` - Use Bun instead of Node.js/npm

  ## Examples

      mix igniter.install live_svelte
      mix igniter.install live_svelte --bun

  """

  import Mix.Tasks.PhoenixVite.Install.Helper

  with_igniter do
    use Igniter.Mix.Task

    alias Igniter.Libs.Phoenix
    alias Igniter.Project.Config

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        composes: ["phoenix_vite.install"],
        schema: [bun: :boolean],
        aliases: [b: :bun]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      app_name = Igniter.Project.Application.app_name(igniter)

      igniter
      |> Igniter.compose_task("phoenix_vite.install", igniter.args.argv)
      |> configure_environments(app_name)
      |> add_live_svelte_to_html_helpers(app_name)
      |> update_javascript_configuration()
      |> configure_tailwind_for_svelte()
      |> update_vite_configuration()
      |> update_package_json_for_svelte()
      |> create_svelte_files()
      |> setup_ssr_for_production(app_name)
      |> update_mix_aliases()
      |> add_svelte_demo_route()
      |> update_home_template()
      |> update_gitignore()
      |> create_ssr_vite_config()
    end

    # Configure environments (config.exs, dev.exs, prod.exs)
    defp configure_environments(igniter, _app_name) do
      igniter
      |> Config.configure("config.exs", :live_svelte, [:ssr], true)
      |> Config.configure("dev.exs", :live_svelte, [:ssr_module], {:code, Sourceror.parse_string!("LiveSvelte.SSR.ViteJS")})
      |> Config.configure("dev.exs", :live_svelte, [:vite_host], "http://localhost:5173")
      |> Config.configure("prod.exs", :live_svelte, [:ssr_module], {:code, Sourceror.parse_string!("LiveSvelte.SSR.NodeJS")})
      |> Config.configure("prod.exs", :live_svelte, [:ssr], true)
    end

    # Add import LiveSvelte to html_helpers in lib/app_web.ex
    defp add_live_svelte_to_html_helpers(igniter, _app_name) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      web_file = Path.join(["lib", web_folder <> ".ex"])

      Igniter.update_file(igniter, web_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "import LiveSvelte") do
            content
          else
            # Add after the use Gettext or import ...Gettext line in html_helpers
            web_module_name = web_module |> Module.split() |> Enum.join(".")

            result =
              String.replace(
                content,
                ~r/(use Gettext, backend: #{Regex.escape(web_module_name)}\.Gettext)/,
                "\\1\n\n      import LiveSvelte"
              )

            # Fallback: try matching import ...Gettext pattern
            if result == content do
              String.replace(
                content,
                ~r/(import #{Regex.escape(web_module_name)}\.Gettext)/,
                "\\1\n\n      import LiveSvelte"
              )
            else
              result
            end
          end
        end)
      end)
    end

    # Update app.js to import getHooks and Components from live_svelte
    defp update_javascript_configuration(igniter) do
      Igniter.update_file(igniter, "assets/js/app.js", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_live_svelte_imports()
          |> update_live_socket_hooks()
        end)
      end)
    end

    defp add_live_svelte_imports(content) do
      if String.contains?(content, "import {getHooks} from \"live_svelte\"") do
        content
      else
        String.replace(
          content,
          "import topbar from \"topbar\"",
          ~s(import topbar from "topbar"\nimport {getHooks} from "live_svelte"\nimport Components from "virtual:live-svelte-components")
        )
      end
    end

    defp update_live_socket_hooks(content) do
      String.replace(
        content,
        "hooks: {...colocatedHooks},",
        "hooks: {...colocatedHooks, ...getHooks(Components)},"
      )
    end

    # Configure Tailwind to include Svelte files (add @source "../svelte"; to app.css)
    defp configure_tailwind_for_svelte(igniter) do
      if Igniter.exists?(igniter, "assets/css/app.css") do
        Igniter.update_file(igniter, "assets/css/app.css", fn source ->
          Rewrite.Source.update(source, :content, fn content ->
            if String.contains?(content, "@source \"../svelte\";") do
              content
            else
              String.replace(
                content,
                "@source \"../js\";",
                ~s(@source "../js";\n@source "../svelte";)
              )
            end
          end)
        end)
      else
        igniter
      end
    end

    # Update vite.config.mjs to add Svelte plugin and liveSveltePlugin
    defp update_vite_configuration(igniter) do
      Igniter.update_file(igniter, "assets/vite.config.mjs", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_svelte_vite_imports()
          |> update_vite_optimized_deps()
          |> update_vite_plugins()
          |> add_ssr_config()
        end)
      end)
    end

    defp add_svelte_vite_imports(content) do
      if String.contains?(content, "import { svelte }") do
        content
      else
        String.replace(
          content,
          "import { phoenixVitePlugin } from 'phoenix_vite'",
          ~s(import { svelte } from "@sveltejs/vite-plugin-svelte"\nimport liveSveltePlugin from "live_svelte/vitePlugin")
        )
      end
    end

    defp update_vite_optimized_deps(content) do
      if String.contains?(content, "\"live_svelte\"") do
        content
      else
        String.replace(
          content,
          ~s(include: ["phoenix", "phoenix_html", "phoenix_live_view"],),
          ~s(include: ["live_svelte", "phoenix", "phoenix_html", "phoenix_live_view"],)
        )
      end
    end

    defp update_vite_plugins(content) do
      if String.contains?(content, "svelte(") do
        content
      else
        String.replace(
          content,
          ~r/phoenixVitePlugin\(\{\s*pattern: \/\\.\(ex\|heex\)\$\/\s*\}\)/s,
          "svelte({ compilerOptions: { css: \"injected\" } }),\n    liveSveltePlugin({ entrypoint: \"./js/server.js\" })"
        )
      end
    end

    defp add_ssr_config(content) do
      if String.contains?(content, "noExternal") do
        content
      else
        String.replace(
          content,
          ~r/build: \{/s,
          "ssr: { noExternal: process.env.NODE_ENV === \"production\" ? true : undefined },\n    build: {"
        )
      end
    end

    # Update package.json with Svelte dependencies
    defp update_package_json_for_svelte(igniter) do
      igniter
      |> Igniter.move_file("assets/package.json", "package.json")
      |> Igniter.update_file("package.json", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_svelte_dependency()
          |> add_svelte_dev_dependencies()
        end)
      end)
    end

    defp add_svelte_dependency(content) do
      if String.contains?(content, "\"live_svelte\"") do
        content
      else
        # Add live_svelte to dependencies section
        String.replace(
          content,
          ~s("phoenix": "file:./deps/phoenix"),
          ~s("live_svelte": "file:./deps/live_svelte",\n    "phoenix": "file:./deps/phoenix")
        )
      end
    end

    defp add_svelte_dev_dependencies(content) do
      if String.contains?(content, "\"@sveltejs/vite-plugin-svelte\"") do
        content
      else
        String.replace(
          content,
          ~s("typescript":),
          ~s("@sveltejs/vite-plugin-svelte": "^5.0.0",\n    "svelte": "^5.0.0",\n    "typescript":)
        )
      end
    end

    # Create Svelte project files
    defp create_svelte_files(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)

      igniter
      |> Igniter.mkdir("assets/svelte")
      |> Igniter.mkdir("lib/#{web_folder}/live")
      |> Igniter.create_new_file("assets/js/server.js", server_js_content())
      |> Igniter.create_new_file(
        "assets/svelte/.gitignore",
        "# Ignore auto-generated Svelte files by ~V sigil\n_build/"
      )
      |> Igniter.create_new_file("assets/svelte/SvelteDemo.svelte", demo_svelte_content())
      |> Igniter.create_new_file(
        "lib/#{web_folder}/live/svelte_demo_live.ex",
        demo_live_view_content(igniter)
      )
    end

    # Setup NodeJS SSR supervisor in application.ex
    defp setup_ssr_for_production(igniter, _app_name) do
      app_module = igniter |> Igniter.Project.Application.app_name() |> to_string()
      app_file = "lib/#{Macro.underscore(app_module)}/application.ex"

      Igniter.update_file(igniter, app_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "children = [") and not String.contains?(content, "NodeJS.Supervisor") do
            String.replace(
              content,
              ~r/(children = \[\s*\n)/,
              "\\1      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},\n"
            )
          else
            content
          end
        end)
      end)
    end

    # Update mix.exs aliases in the consumer app to use Vite
    defp update_mix_aliases(igniter) do
      bun? = igniter.args.options[:bun] || false
      pm = if bun?, do: "bunx", else: "npx"

      Igniter.update_file(igniter, "mix.exs", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "vite build") do
            content
          else
            content
            |> add_assets_js_alias(pm)
            |> update_assets_deploy_alias(pm)
          end
        end)
      end)
    end

    defp add_assets_js_alias(content, pm) do
      if String.contains?(content, "\"assets.js\"") do
        content
      else
        String.replace(
          content,
          ~r/("assets\.setup":)/,
          ~s("assets.js": [\n        "cmd --cd assets #{pm} vite build",\n        "cmd --cd assets #{pm} vite build --config vite.ssr.config.js",\n        "tailwind default"\n      ],\n      \\1)
        )
      end
    end

    defp update_assets_deploy_alias(content, pm) do
      # Replace esbuild references in assets.deploy with Vite commands
      String.replace(
        content,
        ~r/"esbuild default[^"]*"/,
        ~s("cmd --cd assets #{pm} vite build --mode production", "cmd --cd assets #{pm} vite build --config vite.ssr.config.js --mode production")
      )
    end

    # Add svelte_demo route to router
    defp add_svelte_demo_route(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      web_module_name = web_module |> Module.split() |> Enum.join(".")
      router_file = Path.join(["lib", web_folder, "router.ex"])

      Igniter.update_file(igniter, router_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "live \"/svelte_demo\"") do
            content
          else
            if String.contains?(content, "live_dashboard") do
              String.replace(
                content,
                ~r/(live_dashboard.*)/,
                "\\1\n      live \"/svelte_demo\", #{web_module_name}.SvelteDemoLive"
              )
            else
              String.replace(
                content,
                ~r/(pipe_through :browser.*)/,
                "\\1\n      live \"/dev/svelte_demo\", #{web_module_name}.SvelteDemoLive"
              )
            end
          end
        end)
      end)
    end

    # Update home template with LiveSvelte info
    defp update_home_template(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      home_template = Path.join(["lib", web_folder, "controllers", "page_html", "home.html.heex"])

      Igniter.update_file(igniter, home_template, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> String.replace(
            "Peace of mind from prototype to production.",
            "End-to-end reactivity for your Live Svelte apps."
          )
          |> String.replace(
            ~s(<div class="flex">),
            ~s(<a href={~p"/svelte_demo"} class="btn btn-primary mt-4">Svelte Demo</a>\n    <div class="flex">)
          )
        end)
      end)
    end

    # Add gitignore entries for Svelte build artifacts
    defp update_gitignore(igniter) do
      Igniter.update_file(igniter, ".gitignore", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_gitignore_entry("/assets/svelte/_build/")
          |> add_gitignore_entry("/priv/svelte/")
        end)
      end)
    end

    defp add_gitignore_entry(content, entry) do
      if String.contains?(content, entry) do
        content
      else
        content <> "\n#{entry}"
      end
    end

    # Create the SSR Vite config file
    defp create_ssr_vite_config(igniter) do
      Igniter.create_new_file(igniter, "assets/vite.ssr.config.js", ssr_vite_config_content())
    end

    # Content helpers

    defp server_js_content do
      """
      import { getRender } from "live_svelte"
      import Components from "virtual:live-svelte-components"
      export const render = getRender(Components)
      """
    end

    defp ssr_vite_config_content do
      """
      import { defineConfig } from "vite"
      import { svelte } from "@sveltejs/vite-plugin-svelte"

      export default defineConfig({
        plugins: [svelte()],
        ssr: { noExternal: true },
        build: {
          ssr: "./js/server.js",
          outDir: "../priv/svelte",
          rollupOptions: {
            output: { entryFileNames: "server.js", format: "es" }
          }
        }
      })
      """
    end

    defp demo_svelte_content do
      """
      <script>
        let { count, socket } = $props();
      </script>

      <div>
        <h1>LiveSvelte Demo</h1>
        <p>Count: {count}</p>
        <button phx-click="increment">+</button>
        <button phx-click="decrement">-</button>
      </div>
      """
    end

    defp demo_live_view_content(igniter) do
      web_module_name = Phoenix.web_module(igniter) |> Module.split() |> Enum.join(".")

      """
      defmodule #{web_module_name}.SvelteDemoLive do
        use #{web_module_name}, :live_view

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <.svelte name="SvelteDemo" props={%{count: @count}} socket={@socket} />
          \"\"\"
        end

        @impl true
        def mount(_params, _session, socket) do
          {:ok, assign(socket, count: 0)}
        end

        @impl true
        def handle_event("increment", _params, socket) do
          {:noreply, update(socket, :count, &(&1 + 1))}
        end

        @impl true
        def handle_event("decrement", _params, socket) do
          {:noreply, update(socket, :count, &(&1 - 1))}
        end
      end
      """
    end
  else
    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'live_svelte.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
