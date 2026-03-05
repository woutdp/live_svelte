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
        assigns =
          base_assigns(
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

  defp decode_props_diff(html) do
    case Regex.run(~r/data-props-diff="([^"]*)"/, html) do
      [_, encoded] ->
        unescaped =
          encoded
          |> String.replace("&quot;", "\"")
          |> String.replace("&#39;", "'")
          |> String.replace("&#x2B;", "+")

        :json.decode(unescaped)

      _ ->
        nil
    end
  end

  describe "calculate_props_diff/2 (Tier 2 - JSON Patch computation)" do
    test "returns empty list when props are identical" do
      props = %{"count" => 1, "label" => "hello"}
      assert LiveSvelte.calculate_props_diff(props, props) == []
    end

    test "simple value change produces replace operation" do
      diff = LiveSvelte.calculate_props_diff(%{"count" => 2}, %{"count" => 1})
      # includes test op + replace op
      assert length(diff) == 2
      replace = Enum.find(diff, &(&1.op == "replace"))
      assert replace.path == "/count"
      assert replace.value == 2
    end

    test "added key produces add operation" do
      diff = LiveSvelte.calculate_props_diff(%{"a" => 1, "b" => 2}, %{"a" => 1})
      add = Enum.find(diff, &(&1.op == "add"))
      assert add.path == "/b"
      assert add.value == 2
    end

    test "removed key produces remove operation" do
      diff = LiveSvelte.calculate_props_diff(%{"a" => 1}, %{"a" => 1, "b" => 2})
      remove = Enum.find(diff, &(&1.op == "remove"))
      assert remove.path == "/b"
    end

    test "nested map field change produces minimal diff" do
      old_p = %{"user" => %{"name" => "Alice", "age" => 30}}
      new_p = %{"user" => %{"name" => "Alice", "age" => 31}}
      diff = LiveSvelte.calculate_props_diff(new_p, old_p)
      content_ops = Enum.reject(diff, &(&1.op == "test"))
      assert length(content_ops) == 1
      assert hd(content_ops).path == "/user/age"
    end

    test "compressed format is [op, path, value] or [op, path] for remove" do
      diff = LiveSvelte.calculate_props_diff(%{"count" => 5}, %{"count" => 3})
      compressed = Enum.map(diff, &LiveSvelte.prepare_diff/1)
      replace = Enum.find(compressed, fn [op | _] -> op == "replace" end)
      assert replace == ["replace", "/count", 5]
    end

    test "remove compresses to [op, path] without value" do
      diff = LiveSvelte.calculate_props_diff(%{"a" => 1}, %{"a" => 1, "b" => 2})
      compressed = Enum.map(diff, &LiveSvelte.prepare_diff/1)
      remove = Enum.find(compressed, fn [op | _] -> op == "remove" end)
      assert remove == ["remove", "/b"]
    end

    test "unchanged props return empty (no test op)" do
      props = %{"x" => 42, "y" => [1, 2, 3]}
      assert LiveSvelte.calculate_props_diff(props, props) == []
    end

    test "diff is empty when prev_props is nil" do
      assert LiveSvelte.calculate_props_diff(%{"a" => 1}, nil) == []
    end
  end

  describe "Tier 3 - ID-based list diffing via object_hash" do
    test "inserting new item at front with id-list produces fewer ops than N replaces" do
      items_old = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}, %{id: 3, name: "Carol"}]

      items_new = [
        %{id: 4, name: "Dave"},
        %{id: 1, name: "Alice"},
        %{id: 2, name: "Bob"},
        %{id: 3, name: "Carol"}
      ]

      diff = LiveSvelte.calculate_props_diff(%{items: items_new}, %{items: items_old})
      content_ops = Enum.reject(diff, &(&1.op == "test"))

      # With object_hash: should be 1 add (not 3 replaces + 1 add)
      replace_ops = Enum.filter(content_ops, &(&1.op == "replace"))
      assert length(replace_ops) == 0
      assert length(content_ops) <= 2
    end

    test "deleting middle item from id-list produces minimal ops" do
      items_old = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}, %{id: 3, name: "Carol"}]
      items_new = [%{id: 1, name: "Alice"}, %{id: 3, name: "Carol"}]

      diff = LiveSvelte.calculate_props_diff(%{items: items_new}, %{items: items_old})
      content_ops = Enum.reject(diff, &(&1.op == "test"))

      # With object_hash: should be 1 remove (not replace all)
      assert length(content_ops) == 1
      assert hd(content_ops).op == "remove"
    end

    test "reordering id-list produces no replace operations (move semantics)" do
      items_old = [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}, %{id: 3, name: "Carol"}]
      # Move Carol to front
      items_new = [%{id: 3, name: "Carol"}, %{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]

      diff = LiveSvelte.calculate_props_diff(%{items: items_new}, %{items: items_old})
      content_ops = Enum.reject(diff, &(&1.op == "test"))

      # With object_hash: reorder should not produce N replace operations
      replace_ops = Enum.filter(content_ops, &(&1.op == "replace"))
      assert length(replace_ops) == 0
      assert length(content_ops) > 0
    end

    test "list without :id fields still diffs correctly (no regression)" do
      items_old = [%{name: "Alice"}, %{name: "Bob"}]
      items_new = [%{name: "Alice"}, %{name: "Bob"}, %{name: "Carol"}]

      diff = LiveSvelte.calculate_props_diff(%{items: items_new}, %{items: items_old})
      content_ops = Enum.reject(diff, &(&1.op == "test"))
      # Should produce some ops (add for the new item)
      assert length(content_ops) > 0
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

    test "initial render includes data-props-diff attribute as empty array" do
      assigns = base_assigns(props: %{"a" => 1}, __changed__: nil)
      html = render_html(assigns)
      diff = decode_props_diff(html)
      assert diff == []
    end

    test "diff nil is treated as false (strict == true guard), disabling diffing" do
      assigns = base_assigns(props: %{"x" => 1}, __changed__: nil) |> Map.put(:diff, nil)
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
