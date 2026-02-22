defmodule LiveSvelte.TestTest do
  use ExUnit.Case, async: true

  alias LiveSvelte.Test

  # Build HTML with single-quoted attribute values so JSON does not need escaping
  defp svelte_root_html(attrs \\ []) do
    default = [
      id: "Counter-1",
      "data-name": "Counter",
      "data-props": ~s({"count":0}),
      "data-ssr": "false",
      "data-slots": ~s({"default":"PHA+c2xvdDwvcD4="})
    ]
    merged = Keyword.merge(default, attrs)
    attr_str =
      merged
      |> Enum.map(fn {k, v} -> ~s(#{k}='#{v}') end)
      |> Enum.join(" ")
    """
    <div #{attr_str} phx-hook="SvelteHook" phx-update="ignore">
      <div id="Counter-1-target"></div>
    </div>
    """
  end

  describe "get_svelte/1 from HTML" do
    test "returns map with name, id, props, slots, ssr" do
      html = svelte_root_html()
      svelte = Test.get_svelte(html)

      assert svelte.name == "Counter"
      assert svelte.id == "Counter-1"
      assert svelte.props == %{"count" => 0}
      assert svelte.handlers == %{}
      assert svelte.slots["default"] == "<p>slot</p>"
      assert svelte.ssr == false
    end

    test "parses ssr true" do
      html = svelte_root_html("data-ssr": "true")
      assert Test.get_svelte(html).ssr == true
    end

    test "handles empty props and slots" do
      html = svelte_root_html("data-props": ~s({}), "data-slots": ~s({}))
      svelte = Test.get_svelte(html)
      assert svelte.props == %{}
      assert svelte.slots == %{}
    end
  end

  describe "get_svelte/2 from HTML with name option" do
    test "selects component by name" do
      html =
        """
        <div id="A-1" data-name="A" data-props='{}' data-ssr="false" data-slots='{}' phx-hook="SvelteHook"></div>
        <div id="B-1" data-name="B" data-props='{"x":1}' data-ssr="false" data-slots='{}' phx-hook="SvelteHook"></div>
        """
      svelte = Test.get_svelte(html, name: "B")
      assert svelte.name == "B"
      assert svelte.props == %{"x" => 1}
    end

    test "raises when name does not match" do
      html = svelte_root_html()
      assert_raise RuntimeError, ~r/No Svelte component found with name="NotFound"/, fn ->
        Test.get_svelte(html, name: "NotFound")
      end
    end
  end

  describe "get_svelte/2 from HTML with id option" do
    test "selects component by id" do
      html =
        """
        <div id="First" data-name="X" data-props='{}' data-ssr="false" data-slots='{}' phx-hook="SvelteHook"></div>
        <div id="Second" data-name="Y" data-props='{"y":2}' data-ssr="false" data-slots='{}' phx-hook="SvelteHook"></div>
        """
      svelte = Test.get_svelte(html, id: "Second")
      assert svelte.id == "Second"
      assert svelte.props == %{"y" => 2}
    end

    test "raises when id does not match" do
      html = svelte_root_html()
      assert_raise RuntimeError, ~r/No Svelte component found with id="no-such"/, fn ->
        Test.get_svelte(html, id: "no-such")
      end
    end
  end

  describe "get_svelte from HTML with no Svelte components" do
    test "raises when no Svelte root present" do
      html = "<div>plain</div>"
      assert_raise RuntimeError, ~r/No Svelte components found/, fn ->
        Test.get_svelte(html)
      end
    end
  end

  describe "get_svelte from LiveView" do
    test "extracts Svelte component from rendered LiveView component" do
      html =
        Phoenix.LiveViewTest.__render_component__(nil, &LiveSvelte.svelte/1, %{
          name: "TestComponent",
          props: %{value: 42},
          ssr: false,
          socket: nil
        }, [])

      svelte = Test.get_svelte(html)
      assert svelte.name == "TestComponent"
      assert svelte.props["value"] == 42
      assert Map.has_key?(svelte, :id)
      assert svelte.ssr == false
    end

    test "get_svelte(html, name: ...) when HTML from render_component" do
      html =
        Phoenix.LiveViewTest.__render_component__(nil, &LiveSvelte.svelte/1, %{name: "Demo", props: %{}, ssr: false, socket: nil}, [])

      svelte = Test.get_svelte(html, name: "Demo")
      assert svelte.name == "Demo"
    end
  end

  describe "invalid option" do
    test "raises on unknown option" do
      html = svelte_root_html()
      assert_raise ArgumentError, ~r/invalid keyword option/, fn ->
        Test.get_svelte(html, foo: "bar")
      end
    end
  end
end
