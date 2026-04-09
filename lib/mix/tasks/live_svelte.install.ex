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

  # Force-load Igniter from the BEAM path before the with_igniter macro expands.
  # Code.ensure_loaded?/1 only checks modules already in memory; when Mix compiles
  # live_svelte as a newly-fetched dep, Igniter's BEAM files are on the path but not
  # yet loaded into the runtime, causing ensure_loaded? to return false and the else
  # (plain Mix.Task) branch to compile. ensure_compiled/1 loads the module from disk
  # if it hasn't been loaded yet, so ensure_loaded? will return true in with_igniter.
  Code.ensure_compiled(Igniter)

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
      |> update_phoenix_vite_config()
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
    end

    defp update_phoenix_vite_config(igniter) do
      Config.configure(
        igniter,
        "config.exs",
        :phoenix_vite,
        [PhoenixVite.Npm, :assets],
        {:code, Sourceror.parse_string!(~s|[args: [], cd: Path.expand("..", __DIR__)]|)}
      )
    end

    # Configure environments (config.exs, dev.exs, prod.exs)
    defp configure_environments(igniter, _app_name) do
      igniter
      |> Config.configure("config.exs", :live_svelte, [:ssr], true)
      |> Config.configure(
        "dev.exs",
        :live_svelte,
        [:ssr_module],
        {:code, Sourceror.parse_string!("LiveSvelte.SSR.ViteJS")}
      )
      |> Config.configure("dev.exs", :live_svelte, [:vite_host], "http://localhost:5173")
      |> Config.configure(
        "prod.exs",
        :live_svelte,
        [:ssr_module],
        {:code, Sourceror.parse_string!("LiveSvelte.SSR.NodeJS")}
      )
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
            # Primary anchor: `import Phoenix.HTML` is unique to the html_helpers block.
            # Using `use Gettext` as anchor is unsafe — it appears in both controller/0
            # and html_helpers/0, causing `import LiveSvelte` to be injected in both.
            result =
              String.replace(
                content,
                "import Phoenix.HTML",
                "import LiveSvelte\n\n      import Phoenix.HTML",
                global: false
              )

            if result != content do
              result
            else
              # Fallback: use Gettext pattern with global: false so only the first
              # occurrence is replaced. html_helpers is not guaranteed to use
              # `use Gettext` — older Phoenix versions use `import ...Gettext`.
              web_module_name = web_module |> Module.split() |> Enum.join(".")

              result =
                String.replace(
                  content,
                  ~r/(use Gettext, backend: #{Regex.escape(web_module_name)}\.Gettext)/,
                  "\\1\n\n      import LiveSvelte",
                  global: false
                )

              if result != content do
                result
              else
                # Last resort: old-style `import ...Gettext` pattern
                String.replace(
                  content,
                  ~r/(import #{Regex.escape(web_module_name)}\.Gettext)/,
                  "\\1\n\n      import LiveSvelte",
                  global: false
                )
              end
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
      cond do
        String.contains?(content, "getHooks(Components)") ->
          content

        # Phoenix 1.8+ with colocated hooks (most common target)
        String.contains?(content, "hooks: {...colocatedHooks},") ->
          String.replace(
            content,
            "hooks: {...colocatedHooks},",
            "hooks: {...colocatedHooks, ...getHooks(Components)},"
          )

        # Fallback: older Phoenix apps with empty hooks object
        String.contains?(content, "hooks: {},") ->
          String.replace(content, "hooks: {},", "hooks: {...getHooks(Components)},")

        true ->
          content
      end
    end

    # Configure Tailwind to include Svelte files (add @source "../svelte"; to app.css)
    defp configure_tailwind_for_svelte(igniter) do
      if Igniter.exists?(igniter, "assets/css/app.css") do
        Igniter.update_file(igniter, "assets/css/app.css", fn source ->
          Rewrite.Source.update(source, :content, fn content ->
            if String.contains?(content, "@source \"../svelte/**/*.svelte\";") do
              content
            else
              result =
                String.replace(
                  content,
                  "@source \"../js\";",
                  ~s(@source "../js";\n@source "../svelte/**/*.svelte";)
                )

              # Fallback: single-quote variant used by some generators
              if result == content do
                String.replace(
                  content,
                  "@source '../js';",
                  ~s(@source '../js';\n@source "../svelte/**/*.svelte";)
                )
              else
                result
              end
            end
          end)
        end)
      else
        igniter
      end
    end

    # Update vite.config.mjs to add Svelte plugin and liveSveltePlugin.
    defp update_vite_configuration(igniter) do
      Igniter.update_file(igniter, "assets/vite.config.mjs", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_svelte_vite_imports()
          |> update_vite_optimized_deps()
          |> update_vite_plugins()
          |> add_ssr_vite_entry()
        end)
      end)
    end

    defp add_ssr_vite_entry(content) do
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

    # Move package.json to root (like live_vue) and add Svelte + phoenix_vite dependencies.
    # phoenix_vite.install creates assets/package.json; we move to root and patch.
    defp update_package_json_for_svelte(igniter) do
      igniter
      |> Igniter.move_file("assets/package.json", "package.json")
      |> Igniter.update_file("package.json", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> add_module_type()
          |> add_svelte_dependency()
          |> add_svelte_dev_dependencies()
          |> add_phoenix_vite_dev_dependency()
          |> upgrade_vite_version()
          |> fix_deps_paths()
        end)
      end)
    end

    defp add_phoenix_vite_dev_dependency(content) do
      if String.contains?(content, "\"phoenix_vite\"") do
        content
      else
        String.replace(
          content,
          ~s("vite":),
          ~s("phoenix_vite": "file:./deps/phoenix_vite",\n    "vite":),
          global: false
        )
      end
    end

    defp add_svelte_dependency(content) do
      if String.contains?(content, "\"live_svelte\"") do
        content
      else
        # Capture the deps prefix (e.g. "file:../deps" or "file:./deps") from the phoenix entry
        # to match whatever convention the existing package.json uses
        Regex.replace(
          ~r/"phoenix":\s*"(file:[^"]*deps)\/phoenix"/,
          content,
          ~s("live_svelte": "\\1/live_svelte",\n    "phoenix": "\\1/phoenix"),
          global: false
        )
      end
    end

    defp add_svelte_dev_dependencies(content) do
      if String.contains?(content, "\"@sveltejs/vite-plugin-svelte\"") do
        content
      else
        svelte_deps = ~s("@sveltejs/vite-plugin-svelte": "^7.0.0",\n    "svelte": "^5.0.0",\n    )

        result = String.replace(content, ~s("typescript":), svelte_deps <> ~s("typescript":))

        # Fallback: insert before "vite" which is always present in phoenix_vite output
        if result == content do
          String.replace(content, ~s("vite":), svelte_deps <> ~s("vite":))
        else
          result
        end
      end
    end

    defp upgrade_vite_version(content) do
      # @sveltejs/vite-plugin-svelte@7 requires vite@^8; upgrade from the ^6.x
      # default that phoenix_vite.install writes so the peer dep is satisfied.
      String.replace(content, ~s("vite": "^6.3.0"), ~s("vite": "^8.0.0"))
    end

    defp fix_deps_paths(content) do
      # phoenix_vite.install creates assets/package.json with "file:../deps/" paths
      # (relative to assets/). After moving the file to the project root, those paths
      # must become "file:./deps/" so Node can resolve them.
      String.replace(content, "\"file:../deps/", "\"file:./deps/")
    end

    defp add_module_type(content) do
      if String.contains?(content, "\"type\": \"module\"") do
        content
      else
        String.replace(content, "{\n", "{\n  \"type\": \"module\",\n", global: false)
      end
    end

    # Create Svelte project files
    defp create_svelte_files(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)

      igniter
      |> Igniter.mkdir("assets/svelte")
      |> Igniter.create_new_file("assets/js/server.js", server_js_content())
      |> Igniter.create_new_file(
        "assets/svelte/.gitignore",
        "# Ignore auto-generated Svelte files by ~V sigil\n_build/"
      )
      |> Igniter.create_new_file("assets/svelte.config.js", svelte_config_content())
      |> Igniter.create_new_file("assets/svelte/SvelteDemo.svelte", demo_svelte_content())
      |> Igniter.create_new_file(
        "lib/#{web_folder}/svelte_demo_live.ex",
        demo_live_view_content(igniter)
      )
    end

    # Setup NodeJS SSR supervisor in application.ex — only when ssr_module is NodeJS.
    # Generates a compile-env guard so the supervisor is not started in dev mode,
    # where LiveSvelte.SSR.ViteJS is used instead.
    defp setup_ssr_for_production(igniter, _app_name) do
      app_module = igniter |> Igniter.Project.Application.app_name() |> to_string()
      app_file = "lib/#{Macro.underscore(app_module)}/application.ex"

      Igniter.update_file(igniter, app_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "children = [") and
               not String.contains?(content, "NodeJS.Supervisor") do
            # Capture the indentation of `children = [` so the generated code
            # aligns with the surrounding function body regardless of indent style.
            String.replace(
              content,
              ~r/([ \t]*)(children = \[)/,
              "\\1node_js_children =\n" <>
                "\\1  if Application.get_env(:live_svelte, :ssr_module, nil) == LiveSvelte.SSR.NodeJS do\n" <>
                "\\1    [{NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]}]\n" <>
                "\\1  else\n" <>
                "\\1    []\n" <>
                "\\1  end\n\n" <>
                "\\1children = node_js_children ++ [",
              global: false
            )
          else
            content
          end
        end)
      end)
    end

    # Update mix.exs aliases: replace single phoenix_vite.npm vite build with two-step (client + SSR).
    defp update_mix_aliases(igniter) do
      Igniter.update_file(igniter, "mix.exs", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "js/server.js") do
            content
          else
            String.replace(
              content,
              ~s("phoenix_vite.npm vite build"),
              ~s("phoenix_vite.npm vite build --manifest --emptyOutDir true", "phoenix_vite.npm vite build --ssrManifest --emptyOutDir false --ssr js/server.js --outDir ../priv/svelte")
            )
          end
        end)
      end)
    end

    # Add svelte_demo route to router
    defp add_svelte_demo_route(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      router_file = Path.join(["lib", web_folder, "router.ex"])

      Igniter.update_file(igniter, router_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          if String.contains?(content, "live \"/svelte_demo\"") do
            content
          else
            String.replace(
              content,
              ~r/(pipe_through[( ]:?browser\)?.*)/,
              "\\1\n    live \"/svelte_demo\", SvelteDemoLive",
              global: false
            )
          end
        end)
      end)
    end

    # Update home template with LiveSvelte info.
    # The anchor strings are Phoenix version-specific; if they aren't found we
    # warn rather than silently do nothing so the developer knows to add the link
    # manually.
    defp update_home_template(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      home_template = Path.join(["lib", web_folder, "controllers", "page_html", "home.html.heex"])

      Igniter.update_file(igniter, home_template, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          updated =
            content
            |> String.replace(
              "Peace of mind from prototype to production.",
              "End-to-end reactivity for your Live Svelte apps."
            )
            |> String.replace(
              ~s(<div class="flex">),
              ~s(<a href={~p"/svelte_demo"} class="btn btn-primary mt-4">Svelte Demo</a>\n    <div class="flex">)
            )

          if updated == content do
            Mix.shell().info(
              "Note: home template (#{home_template}) was not modified — " <>
                "the expected anchor text was not found (Phoenix home page may have changed). " <>
                "Manually add a link to /svelte_demo if desired."
            )
          end

          updated
        end)
      end)
    end

    # Add gitignore entries; with package.json at root, node_modules is at project root.
    defp update_gitignore(igniter) do
      Igniter.update_file(igniter, ".gitignore", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> then(fn c ->
            if String.contains?(c, "/assets/node_modules"),
              do: String.replace(c, "/assets/node_modules", "node_modules"),
              else: c
          end)
          |> then(fn c ->
            if String.contains?(c, "/priv/svelte/"),
              do: c,
              else:
                String.trim_trailing(c) <>
                  "\n\n# LiveSvelte build artifacts\n/assets/svelte/_build/\n/priv/svelte/\n"
          end)
        end)
      end)
    end

    # Content helpers

    defp svelte_config_content do
      """
      import { vitePreprocess } from "@sveltejs/vite-plugin-svelte"

      export default {
        preprocess: vitePreprocess(),
      }
      """
    end

    defp server_js_content do
      """
      import { getRender } from "live_svelte"
      import Components from "virtual:live-svelte-components"
      export const render = getRender(Components)
      """
    end

    defp demo_svelte_content do
      """
      <script>
        let { count } = $props();
      </script>

      <div class="card">
        <div class="badge">LiveSvelte</div>
        <h1>End-to-end reactivity</h1>
        <p class="subtitle">This counter is powered by a Phoenix LiveView server — no page reload needed.</p>

        <div class="counter">
          <button class="btn btn-ghost" phx-click="decrement" aria-label="Decrement">−</button>
          <span class="count">{count}</span>
          <button class="btn btn-primary" phx-click="increment" aria-label="Increment">+</button>
        </div>

        <p class="hint">Click the buttons to update server state via the LiveView websocket.</p>
      </div>

      <style>
        .card {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 1rem;
          max-width: 420px;
          margin: 4rem auto;
          padding: 2.5rem 2rem;
          background: #ffffff;
          border: 1px solid #e5e7eb;
          border-radius: 1rem;
          box-shadow: 0 4px 24px rgba(0, 0, 0, 0.07);
          font-family: system-ui, -apple-system, sans-serif;
          text-align: center;
        }

        .badge {
          display: inline-flex;
          align-items: center;
          gap: 0.375rem;
          padding: 0.25rem 0.75rem;
          background: #fff7ed;
          color: #f97316;
          border: 1px solid #fed7aa;
          border-radius: 9999px;
          font-size: 0.75rem;
          font-weight: 600;
          letter-spacing: 0.05em;
          text-transform: uppercase;
        }

        .badge::before {
          content: '';
          display: inline-block;
          width: 6px;
          height: 6px;
          background: #f97316;
          border-radius: 50%;
          animation: pulse 2s ease-in-out infinite;
        }

        h1 {
          margin: 0;
          font-size: 1.5rem;
          font-weight: 700;
          color: #111827;
          letter-spacing: -0.02em;
        }

        .subtitle {
          margin: 0;
          font-size: 0.875rem;
          color: #6b7280;
          line-height: 1.5;
        }

        .counter {
          display: flex;
          align-items: center;
          gap: 1.25rem;
          margin: 0.5rem 0;
        }

        .count {
          min-width: 3.5rem;
          font-size: 3rem;
          font-weight: 800;
          color: #111827;
          letter-spacing: -0.04em;
          font-variant-numeric: tabular-nums;
          transition: transform 0.1s ease;
        }

        .btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 2.75rem;
          height: 2.75rem;
          border: none;
          border-radius: 50%;
          font-size: 1.5rem;
          font-weight: 400;
          line-height: 1;
          cursor: pointer;
          transition: background 0.15s ease, transform 0.1s ease, box-shadow 0.15s ease;
        }

        .btn:active {
          transform: scale(0.93);
        }

        .btn-primary {
          background: #f97316;
          color: #ffffff;
          box-shadow: 0 2px 8px rgba(249, 115, 22, 0.35);
        }

        .btn-primary:hover {
          background: #ea6c0b;
          box-shadow: 0 4px 14px rgba(249, 115, 22, 0.45);
        }

        .btn-ghost {
          background: #f3f4f6;
          color: #374151;
        }

        .btn-ghost:hover {
          background: #e5e7eb;
        }

        .hint {
          margin: 0;
          font-size: 0.75rem;
          color: #9ca3af;
        }

        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }

        @media (prefers-color-scheme: dark) {
          .card {
            background: #1f2937;
            border-color: #374151;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.3);
          }
          h1 { color: #f9fafb; }
          .count { color: #f9fafb; }
          .subtitle { color: #9ca3af; }
          .badge {
            background: #431407;
            border-color: #ea6c0b;
            color: #fdba74;
          }
          .badge::before { background: #fb923c; }
          .btn-ghost {
            background: #374151;
            color: #d1d5db;
          }
          .btn-ghost:hover { background: #4b5563; }
        }
      </style>
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
