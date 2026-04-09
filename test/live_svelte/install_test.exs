defmodule Mix.Tasks.LiveSvelte.InstallTest do
  use ExUnit.Case, async: false

  import Igniter.Test

  # phx_test_project/1 runs igniter.phx.install to create a proper Phoenix
  # project skeleton — required so that phoenix_vite.install (composed by
  # live_svelte.install) can find the endpoint, web module, router, etc.
  defp run_installer(opts \\ []) do
    argv = if opts[:bun], do: ["--bun", "--yes"], else: ["--yes"]

    phx_test_project()
    |> Igniter.compose_task("live_svelte.install", argv)
  end

  defp file_content(igniter, path) do
    source = Rewrite.source!(igniter.rewrite, path)
    Rewrite.Source.get(source, :content)
  end

  defp count_occurrences(string, pattern) do
    string |> String.split(pattern) |> length() |> Kernel.-(1)
  end

  describe "H1 regression: add_live_svelte_to_html_helpers/2" do
    test "import LiveSvelte appears exactly once in web module" do
      result = run_installer()
      web_file = "lib/test_web.ex"
      content = file_content(result, web_file)
      occurrences = count_occurrences(content, "import LiveSvelte")

      assert occurrences == 1,
             "Expected exactly 1 `import LiveSvelte`, found #{occurrences}:\n\n#{content}"
    end

    test "import LiveSvelte is not in the controller/0 block" do
      result = run_installer()
      content = file_content(result, "lib/test_web.ex")

      # Split on html_helpers definition to isolate controller block
      [controller_section | _] = String.split(content, "defp html_helpers", parts: 2)

      refute controller_section =~ "import LiveSvelte",
             "import LiveSvelte must not appear in the controller/0 block:\n\n#{controller_section}"
    end

    test "import LiveSvelte is inside html_helpers" do
      result = run_installer()
      content = file_content(result, "lib/test_web.ex")

      assert content =~ ~r/defp html_helpers.*import LiveSvelte/s,
             "import LiveSvelte not found inside html_helpers block"
    end
  end

  describe "H2: phoenix_vite two-step assets.build" do
    test "assets.build includes phoenix_vite.npm client and SSR build steps" do
      result = run_installer()
      content = file_content(result, "mix.exs")

      assert content =~ "phoenix_vite.npm vite build --manifest --emptyOutDir true",
             "assets.build missing client step:\n\n#{content}"

      assert content =~ "phoenix_vite.npm vite build --ssrManifest",
             "assets.build missing SSR step:\n\n#{content}"

      assert content =~ "--ssr js/server.js",
             "assets.build SSR step must use js/server.js entry:\n\n#{content}"

      assert content =~ "--outDir ../priv/svelte",
             "assets.build SSR step must output to priv/svelte:\n\n#{content}"
    end
  end

  describe "M2: vite config — ssr noExternal in main config" do
    test "vite.config.mjs contains ssr noExternal for production" do
      result = run_installer()
      content = file_content(result, "assets/vite.config.mjs")

      assert content =~ "noExternal",
             "vite.config.mjs must have ssr.noExternal for SSR build"
    end
  end

  describe "M3: update_live_socket_hooks/1 fallback" do
    test "getHooks(Components) is added to LiveSocket hooks" do
      result = run_installer()
      content = file_content(result, "assets/js/app.js")

      assert content =~ "getHooks(Components)",
             "getHooks(Components) not found in app.js hooks"
    end
  end

  describe "M4: route indentation" do
    test "svelte_demo route uses 4-space indent inside scope" do
      result = run_installer()
      content = file_content(result, "lib/test_web/router.ex")

      assert content =~ ~r/^    live "\/svelte_demo"/m,
             "live route has wrong indentation (expected 4 spaces):\n#{content}"
    end
  end

  describe "config files" do
    test "config.exs sets phoenix_vite and live_svelte ssr" do
      result = run_installer()
      content = file_content(result, "config/config.exs")
      assert content =~ ~r/:phoenix_vite.*PhoenixVite\.Npm/s
      assert content =~ ~r/:live_svelte.*ssr.*true/s
    end

    test "dev.exs sets ViteJS SSR module" do
      result = run_installer()
      content = file_content(result, "config/dev.exs")
      assert content =~ "LiveSvelte.SSR.ViteJS"
    end

    test "prod.exs sets NodeJS SSR module" do
      result = run_installer()
      content = file_content(result, "config/prod.exs")
      assert content =~ "LiveSvelte.SSR.NodeJS"
    end
  end

  describe "package.json (root)" do
    test "package.json is at project root with live_svelte dependency" do
      result = run_installer()
      content = file_content(result, "package.json")
      assert content =~ "live_svelte"
    end

    test "phoenix_vite and svelte dev dependencies added" do
      result = run_installer()
      content = file_content(result, "package.json")
      assert content =~ "phoenix_vite"
      assert content =~ "@sveltejs/vite-plugin-svelte"
      assert content =~ ~s("svelte":)
    end

    test "type module is set" do
      result = run_installer()
      content = file_content(result, "package.json")
      assert content =~ ~s("type": "module"), "package.json must have \"type\": \"module\""
    end

    test "svelte plugin version is ^7.0.0, not older ^5.0.0" do
      result = run_installer()
      content = file_content(result, "package.json")

      assert content =~ ~s("@sveltejs/vite-plugin-svelte": "^7.0.0"),
             "Expected @sveltejs/vite-plugin-svelte ^7.0.0 (requires vite@8), got:\n#{content}"

      refute content =~ ~s("@sveltejs/vite-plugin-svelte": "^5.0.0"),
             "@sveltejs/vite-plugin-svelte ^5.0.0 is too old — use ^7.0.0 with vite@8"
    end

    test "vite version is ^8.0.0 to satisfy vite-plugin-svelte@7 peer dep" do
      result = run_installer()
      content = file_content(result, "package.json")

      assert content =~ ~s("vite": "^8.0.0"),
             "Expected vite ^8.0.0 (required by @sveltejs/vite-plugin-svelte@7), got:\n#{content}"

      refute content =~ ~s("vite": "^6.3.0"),
             "vite ^6.3.0 (phoenix_vite default) must be upgraded to ^8.0.0"
    end

    test "deps use ./deps/ paths, not ../deps/, after package.json is moved to project root" do
      result = run_installer()
      content = file_content(result, "package.json")

      refute content =~ "file:../deps/",
             "package.json at project root must use file:./deps/ paths, not file:../deps/:\n#{content}"

      assert content =~ "file:./deps/",
             "package.json must reference Elixir deps via file:./deps/ paths"
    end
  end

  describe "tailwind source glob" do
    test "app.css uses explicit svelte glob, not bare directory" do
      result = run_installer()

      case Rewrite.source(result.rewrite, "assets/css/app.css") do
        {:ok, source} ->
          content = Rewrite.Source.get(source, :content)

          if content =~ "@source" do
            refute content =~ ~s(@source "../svelte";),
                   "app.css must not use bare @source \"../svelte\" — .svelte extension is not in Tailwind's default scan list"

            assert content =~ ~s(@source "../svelte/**/*.svelte";),
                   "app.css must use the explicit glob @source \"../svelte/**/*.svelte\""
          end

        {:error, _} ->
          # app.css not modified by installer (no Tailwind in test project) — skip
          :ok
      end
    end
  end

  describe "application.ex (M1: conditional NodeJS.Supervisor)" do
    test "NodeJS.Supervisor is present in application.ex" do
      result = run_installer()
      content = file_content(result, "lib/test/application.ex")
      assert content =~ "NodeJS.Supervisor"
    end

    test "NodeJS.Supervisor is wrapped in get_env guard, not unconditional" do
      result = run_installer()
      content = file_content(result, "lib/test/application.ex")

      assert content =~ "Application.get_env(:live_svelte, :ssr_module",
             "NodeJS.Supervisor must be wrapped in a get_env guard so it only starts in prod"

      refute content =~ ~r/children\s*=\s*\[\s*\{NodeJS\.Supervisor/,
             "NodeJS.Supervisor must not be a bare unconditional entry in the children list"
    end

    test "node_js_children variable uses LiveSvelte.SSR.NodeJS as the condition" do
      result = run_installer()
      content = file_content(result, "lib/test/application.ex")
      assert content =~ "LiveSvelte.SSR.NodeJS"
    end

    test "children list uses node_js_children ++ [" do
      result = run_installer()
      content = file_content(result, "lib/test/application.ex")
      assert content =~ "node_js_children ++ ["
    end
  end

  describe "gitignore (L3: section header)" do
    test "svelte build artifacts are gitignored" do
      result = run_installer()
      content = file_content(result, ".gitignore")
      assert content =~ "/assets/svelte/_build/"
      assert content =~ "/priv/svelte/"
    end

    test "gitignore entries are grouped under a LiveSvelte section comment" do
      result = run_installer()
      content = file_content(result, ".gitignore")

      assert content =~ "# LiveSvelte build artifacts",
             "Gitignore entries should be under a named section comment"
    end

    test "gitignore entries appear after the section comment" do
      result = run_installer()
      content = file_content(result, ".gitignore")

      section_pos = :binary.match(content, "# LiveSvelte build artifacts") |> elem(0)
      priv_pos = :binary.match(content, "/priv/svelte/") |> elem(0)

      assert section_pos < priv_pos
    end
  end

  describe "created files" do
    test "assets/js/server.js is created" do
      result = run_installer()
      assert_creates(result, "assets/js/server.js")
    end

    test "SvelteDemo.svelte is created" do
      result = run_installer()
      assert_creates(result, "assets/svelte/SvelteDemo.svelte")
    end

    test "svelte_demo_live.ex is created" do
      result = run_installer()
      assert_creates(result, "lib/test_web/svelte_demo_live.ex")
    end
  end

  describe "idempotency" do
    test "running installer twice does not duplicate import LiveSvelte" do
      base = phx_test_project()

      result =
        base
        |> Igniter.compose_task("live_svelte.install", ["--yes"])
        |> Igniter.compose_task("live_svelte.install", ["--yes"])

      content = file_content(result, "lib/test_web.ex")
      assert count_occurrences(content, "import LiveSvelte") == 1
    end
  end
end
