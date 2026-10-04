defmodule LiveSvelte.SigilVTest do
  use ExUnit.Case, async: false

  test "regenerates a missing ~V artifact on the next compile" do
    project =
      Path.join(System.tmp_dir!(), "live_svelte_sigil_v_#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(project) end)

    File.mkdir_p!(Path.join(project, "lib"))
    File.write!(Path.join(project, "mix.exs"), mix_exs())
    File.write!(Path.join(project, "lib/sigil_v_fixture.ex"), fixture_source())

    artifact = Path.join(project, "assets/svelte/_build/Elixir.SigilVFixture.svelte")

    compile!(project)
    assert File.read!(artifact) == "<p>hello</p>\n"

    File.rm!(artifact)
    compile!(project)
    assert File.read!(artifact) == "<p>hello</p>\n"
  end

  defp compile!(project) do
    ebins =
      Mix.Project.build_path()
      |> Path.join("lib/*/ebin")
      |> Path.wildcard()

    args =
      Enum.flat_map(ebins, &["-pa", &1]) ++
        ["-S", "mix", "compile", "--no-deps-check", "--no-prune-code-paths"]

    {output, status} =
      System.cmd("elixir", args,
        cd: project,
        stderr_to_stdout: true,
        env: [{"MIX_ENV", to_string(Mix.env())}]
      )

    assert status == 0, output
  end

  # Heredoc dedent strips the indentation shared with the closing delimiter,
  # so the sigil body written to disk is "<p>hello</p>\n".
  defp fixture_source do
    """
    defmodule SigilVFixture do
      use Phoenix.Component
      import LiveSvelte

      def render(assigns) do
        ~V\"\"\"
        <p>hello</p>
        \"\"\"
      end
    end
    """
  end

  defp mix_exs do
    """
    defmodule SigilVFixture.MixProject do
      use Mix.Project

      def project do
        [
          app: :sigil_v_fixture,
          version: "0.1.0",
          elixir: "~> 1.17",
          consolidate_protocols: false,
          deps: []
        ]
      end
    end
    """
  end
end
