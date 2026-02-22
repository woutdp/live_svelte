defmodule LiveSvelte.PropsDiffTest do
  # This test mutates Application env in a couple cases.
  use ExUnit.Case, async: false

  defp base_assigns(opts \\ []) do
    %{
      __changed__: Keyword.get(opts, :__changed__, nil),
      socket: Keyword.get(opts, :socket),
      name: Keyword.get(opts, :name, "Demo"),
      id: nil,
      key: nil,
      props: Keyword.get(opts, :props, %{}),
      live_json_props: %{},
      ssr: false,
      class: nil,
      loading: [],
      inner_block: []
    }
  end

  defp render_html(assigns) do
    assigns
    |> LiveSvelte.svelte()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp data_use_diff_from_html(html) do
    case Regex.run(~r/data-use-diff="([^"]*)"/, html) do
      [_, val] -> val
      _ -> nil
    end
  end

  defp decode_props(html) do
    case Regex.run(~r/data-props="([^"]*)"/, html) do
      [_, encoded] ->
        # Attribute value may be HTML-escaped (e.g. &quot; for ")
        unescaped =
          encoded
          |> String.replace("&quot;", "\"")
          |> String.replace("&#39;", "'")
        # Use Erlang :json (same family as default LiveSvelte.JSON encoder)
        :json.decode(unescaped)
      _ ->
        nil
    end
  end

  describe "props_changed_only/2 (changed-keys extraction)" do
    test "returns only keys that differ between new and old" do
      old_p = %{"a" => 1, "b" => 2, "c" => 3}
      new_p = %{"a" => 1, "b" => 99, "c" => 3}
      result = LiveSvelte.props_changed_only(new_p, old_p)
      assert result == %{"b" => 99}
    end

    test "includes keys only in new (added)" do
      old_p = %{"a" => 1}
      new_p = %{"a" => 1, "b" => 2}
      result = LiveSvelte.props_changed_only(new_p, old_p)
      assert result == %{"b" => 2}
    end

    test "includes keys only in old as nil (removed)" do
      old_p = %{"a" => 1, "b" => 2}
      new_p = %{"a" => 1}
      result = LiveSvelte.props_changed_only(new_p, old_p)
      assert result == %{"b" => nil}
    end

    test "when old is empty, returns all new keys" do
      new_p = %{"x" => 1, "y" => 2}
      result = LiveSvelte.props_changed_only(new_p, %{})
      assert result == new_p
    end
  end

  describe "props_for_payload/1 (payload selection logic)" do
    test "init (__changed__ nil) returns full props" do
      props = %{"a" => 1, "b" => 2}
      assigns = base_assigns(props: props, __changed__: nil)
      result = LiveSvelte.props_for_payload(assigns)
      assert result == props
    end

    test "when enable_props_diff is false, always returns full props" do
      Application.put_env(:live_svelte, :enable_props_diff, false)
      try do
        assigns = base_assigns(
          props: %{"x" => 10, "y" => 20},
          __changed__: %{props: %{"x" => 10, "y" => 0}}
        )
        # In real component rendering, `diff` is present (default true). Ensure global config still wins.
        assigns = Map.put(assigns, :diff, true)
        result = LiveSvelte.props_for_payload(assigns)
        assert result == %{"x" => 10, "y" => 20}
      after
        Application.put_env(:live_svelte, :enable_props_diff, true)
      end
    end
  end

  describe "rendered output" do
    test "initial render sends full props and data-use-diff true" do
      assigns = base_assigns(props: %{"a" => 1, "b" => 2}, __changed__: nil)
      html = render_html(assigns)
      props = decode_props(html)
      assert props["a"] == 1
      assert props["b"] == 2
      assert data_use_diff_from_html(html) == "true"
    end

    test "when diff false, data-use-diff is false" do
      assigns = base_assigns(props: %{"x" => 1}, __changed__: nil) |> Map.put(:diff, false)
      html = render_html(assigns)
      assert data_use_diff_from_html(html) == "false"
    end

    test "when enable_props_diff is false, data-use-diff is false even if diff defaults to true" do
      Application.put_env(:live_svelte, :enable_props_diff, false)

      try do
        # No explicit `diff` attr; component default is true.
        assigns = base_assigns(props: %{"x" => 1}, __changed__: nil)
        html = render_html(assigns)
        assert data_use_diff_from_html(html) == "false"
      after
        Application.put_env(:live_svelte, :enable_props_diff, true)
      end
    end
  end
end
