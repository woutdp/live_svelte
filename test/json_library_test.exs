defmodule LiveSvelte.JSONLibraryTest do
  # must be synchronous, tests are sensitive to config changes
  use ExUnit.Case, async: false

  describe "default JSON library" do
    test "uses Jason by default when no config is provided" do
      load_config("config/config.exs")
      json_library = Application.get_env(:live_svelte, :json_library, Jason)
      assert json_library == Jason
    end

    test "encodes props correctly with Jason" do
      load_config("config/config.exs")

      data = %{foo: "bar", baz: 123}

      # Call the private json/1 function through the public API
      # by testing that the component renders with correct data attributes
      assigns = %{
        __changed__: nil,
        socket: nil,
        name: "Test",
        props: data,
        live_json_props: %{},
        ssr: false,
        class: nil,
        loading: [],
        inner_block: []
      }

      result = LiveSvelte.svelte(assigns)
      html = Phoenix.HTML.Safe.to_iodata(result) |> IO.iodata_to_binary()

      # HTML entities are escaped in the output
      assert html =~ ~s(data-props="{&quot;foo&quot;:&quot;bar&quot;,&quot;baz&quot;:123}")
    end
  end

  describe "custom JSON library" do
    test "uses custom library when configured" do
      load_config("test/json_library_test/custom_json_config.exs")
      json_library = Application.get_env(:live_svelte, :json_library)
      assert json_library == TestJSONLibrary
    end

    test "calls custom library's encode!/1 function" do
      load_config("test/json_library_test/custom_json_config.exs")

      data = %{test: "data"}

      assigns = %{
        __changed__: nil,
        socket: nil,
        name: "Test",
        props: data,
        live_json_props: %{},
        ssr: false,
        class: nil,
        loading: [],
        inner_block: []
      }

      result = LiveSvelte.svelte(assigns)
      html = Phoenix.HTML.Safe.to_iodata(result) |> IO.iodata_to_binary()

      # Should contain the test library's output
      assert html =~ ~s(data-props="TEST_ENCODED:%{test: &quot;data&quot;}")
    end
  end

  describe "backward compatibility" do
    test "existing code works without configuration changes" do
      # Reset to default config
      load_config("config/config.exs")

      # Verify Jason is used as default
      json_library = Application.get_env(:live_svelte, :json_library, Jason)
      assert json_library == Jason

      # Verify encoding works as before
      data = %{legacy: "test"}

      assigns = %{
        __changed__: nil,
        socket: nil,
        name: "Legacy",
        props: data,
        live_json_props: %{},
        ssr: false,
        class: nil,
        loading: [],
        inner_block: []
      }

      result = LiveSvelte.svelte(assigns)
      html = Phoenix.HTML.Safe.to_iodata(result) |> IO.iodata_to_binary()

      # HTML entities are escaped in the output
      assert html =~ ~s(data-props="{&quot;legacy&quot;:&quot;test&quot;}")
    end
  end

  # Helper function to reload configuration
  # Pattern copied from ssr_test.exs:27-34
  defp load_config(path) do
    Application.started_applications(:infinity)
    |> Enum.reduce([], fn {app, _, _}, acc ->
      [{app, Application.get_all_env(app)} | acc]
    end)
    |> Config.Reader.merge(Config.Reader.read!(path))
    |> Application.put_all_env()
  end
end
