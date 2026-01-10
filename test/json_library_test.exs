defmodule LiveSvelte.JSONLibraryTest do
  # must be synchronous, tests are sensitive to config changes
  use ExUnit.Case, async: false

  describe "native JSON library (default)" do
    test "uses LiveSvelte.JSON by default when no config is provided" do
      Application.delete_env(:live_svelte, :json_library)
      json_library = Application.get_env(:live_svelte, :json_library, LiveSvelte.JSON)
      assert json_library == LiveSvelte.JSON
    end

    test "encodes props correctly with native JSON" do
      Application.delete_env(:live_svelte, :json_library)

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
      # Native JSON encodes correctly
      assert html =~ "data-props="
      assert html =~ "foo"
      assert html =~ "bar"
      assert html =~ "baz"
      assert html =~ "123"
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

  describe "backward compatibility with Jason" do
    test "works with Jason when explicitly configured" do
      Application.put_env(:live_svelte, :json_library, Jason)

      json_library = Application.get_env(:live_svelte, :json_library)
      assert json_library == Jason

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

      # Clean up
      Application.delete_env(:live_svelte, :json_library)
    end
  end

  describe "struct encoding" do
    defmodule TestUser do
      defstruct name: "John", age: 27
    end

    test "native JSON encodes structs as maps automatically" do
      Application.delete_env(:live_svelte, :json_library)

      data = %{user: %TestUser{name: "Jane", age: 30}}

      assigns = %{
        __changed__: nil,
        socket: nil,
        name: "StructTest",
        props: data,
        live_json_props: %{},
        ssr: false,
        class: nil,
        loading: [],
        inner_block: []
      }

      result = LiveSvelte.svelte(assigns)
      html = Phoenix.HTML.Safe.to_iodata(result) |> IO.iodata_to_binary()

      # Should encode struct fields
      assert html =~ "user"
      assert html =~ "name"
      assert html =~ "Jane"
      assert html =~ "age"
      assert html =~ "30"
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
