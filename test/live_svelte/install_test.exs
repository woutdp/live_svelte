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

  describe "H2 regression: update_assets_deploy_alias/2" do
    test "assets.deploy includes SSR vite build step" do
      result = run_installer()
      content = file_content(result, "mix.exs")

      assert content =~ "vite.ssr.config.js",
             "assets.deploy is missing the SSR build step:\n\n#{content}"
    end

    test "assets.deploy SSR step uses npx by default" do
      result = run_installer()
      content = file_content(result, "mix.exs")

      assert content =~
               ~r/npx vite build --config vite\.ssr\.config\.js --mode production/,
             "Expected npx SSR build in assets.deploy"
    end

    test "assets.deploy SSR step uses bunx with --bun flag" do
      result = run_installer(bun: true)
      content = file_content(result, "mix.exs")

      assert content =~
               ~r/bunx vite build --config vite\.ssr\.config\.js --mode production/,
             "Expected bunx SSR build in assets.deploy with --bun"
    end
  end

  describe "assets.js alias" do
    test "assets.js alias is added with client and SSR build steps" do
      result = run_installer()
      content = file_content(result, "mix.exs")

      assert content =~ ~s("assets.js":),
             "assets.js alias is missing from mix.exs"

      assert content =~ ~r/"assets\.js".*vite\.ssr\.config\.js/s,
             "assets.js alias missing SSR step"
    end
  end

  describe "M2: vite config — no noExternal in client config" do
    test "client vite.config.mjs does not contain noExternal" do
      result = run_installer()
      content = file_content(result, "assets/vite.config.mjs")

      refute content =~ "noExternal",
             "ssr.noExternal must NOT appear in client vite.config.mjs (belongs only in vite.ssr.config.js)"
    end

    test "SSR vite.ssr.config.js correctly contains noExternal" do
      result = run_installer()
      content = file_content(result, "assets/vite.ssr.config.js")

      assert content =~ "noExternal: true",
             "vite.ssr.config.js must have ssr.noExternal: true"
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
    test "config.exs sets ssr: true" do
      result = run_installer()
      content = file_content(result, "config/config.exs")
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

  describe "package.json" do
    test "live_svelte dependency added" do
      result = run_installer()
      content = file_content(result, "assets/package.json")
      assert content =~ "live_svelte"
    end

    test "svelte dev dependencies added" do
      result = run_installer()
      content = file_content(result, "assets/package.json")
      assert content =~ "@sveltejs/vite-plugin-svelte"
      assert content =~ ~s("svelte":)
    end
  end

  describe "application.ex" do
    test "NodeJS.Supervisor added to children" do
      result = run_installer()
      content = file_content(result, "lib/test/application.ex")
      assert content =~ "NodeJS.Supervisor"
    end
  end

  describe "gitignore" do
    test "svelte build artifacts are gitignored" do
      result = run_installer()
      content = file_content(result, ".gitignore")
      assert content =~ "/assets/svelte/_build/"
      assert content =~ "/priv/svelte/"
    end
  end

  describe "created files" do
    test "assets/vite.ssr.config.js is created" do
      result = run_installer()
      assert_creates(result, "assets/vite.ssr.config.js")
    end

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
