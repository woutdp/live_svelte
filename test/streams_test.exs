defmodule LiveSvelte.StreamsTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.LiveStream

  # Build a %LiveStream{} compatible with library's phoenix_live_view 0.18.15.
  # Inserts are 3-tuples {dom_id, at, item} in 0.18.15 and 4-tuples {dom_id, at, item, limit}
  # in 1.0.x. We test the 3-tuple format here; limit + reset? are covered in example project tests.
  defp make_stream(opts \\ []) do
    %LiveStream{
      name: :items,
      dom_id: fn item -> "items-#{item.id}" end,
      inserts: Keyword.get(opts, :inserts, []),
      deletes: Keyword.get(opts, :deletes, [])
    }
  end

  defp base_assigns(opts \\ []) do
    %{
      __changed__: nil,
      socket: nil,
      name: "Demo",
      id: nil,
      key: nil,
      props: %{},
      live_json_props: %{},
      ssr: false,
      class: nil,
      loading: [],
      inner_block: [],
      diff: true
    }
    |> Map.merge(Map.new(opts))
  end

  defp render_html(assigns) do
    assigns
    |> LiveSvelte.svelte()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp decode_streams_diff(html) do
    case Regex.run(~r/data-streams-diff="([^"]*)"/, html) do
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

  describe "data-streams-diff attribute" do
    test "component without stream assigns has empty data-streams-diff" do
      assigns = base_assigns()
      html = render_html(assigns)
      diff = decode_streams_diff(html)
      assert diff == []
    end

    test "component with stream assign has non-nil data-streams-diff" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Alice"}}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)
      assert diff != nil
      assert is_list(diff)
    end

    test "ops are compressed to [op, path, value] or [op, path] format" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Alice"}}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      Enum.each(diff, fn op ->
        assert is_list(op)
        assert length(op) in [2, 3]
        assert Enum.at(op, 0) in ["replace", "upsert", "remove", "limit", "test"]
        assert is_binary(Enum.at(op, 1))
      end)
    end
  end

  describe "insert ops" do
    test "initial render: single insert at -1 produces replace-then-upsert" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Alice"}}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      # Initial render produces replace (empty) + upsert
      replace_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "replace" && Enum.at(op, 1) == "/items" end)
      assert replace_op != nil
      assert Enum.at(replace_op, 2) == []

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op != nil
      assert Enum.at(upsert_op, 1) == "/items/-"

      # Order matters: replace MUST come before upsert so the array exists before items are inserted
      replace_idx = Enum.find_index(diff, fn op -> Enum.at(op, 0) == "replace" && Enum.at(op, 1) == "/items" end)
      upsert_idx = Enum.find_index(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert replace_idx < upsert_idx, "replace [] must precede upsert ops (got replace at #{replace_idx}, upsert at #{upsert_idx})"
    end

    test "insert at 0 produces upsert with path /items/0" do
      stream = make_stream(inserts: [{"items-1", 0, %{id: 1, name: "Alice"}}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op != nil
      assert Enum.at(upsert_op, 1) == "/items/0"
    end

    test "upsert value includes __dom_id field" do
      stream = make_stream(inserts: [{"items-42", -1, %{id: 42, name: "Test"}}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      item = Enum.at(upsert_op, 2)
      assert item["__dom_id"] == "items-42"
      assert item["id"] == 42
      assert item["name"] == "Test"
    end

    test "multiple inserts at -1 produce multiple upsert ops" do
      stream =
        make_stream(
          inserts: [
            {"items-2", -1, %{id: 2, name: "Bob"}},
            {"items-1", -1, %{id: 1, name: "Alice"}}
          ]
        )

      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_ops = Enum.filter(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert length(upsert_ops) == 2
    end
  end

  describe "delete ops" do
    test "delete produces remove op with $$dom_id path" do
      stream = make_stream(deletes: ["items-2"])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      remove_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "remove" end)
      assert remove_op != nil
      assert Enum.at(remove_op, 1) == "/items/$$items-2"
    end

    test "multiple deletes produce multiple remove ops" do
      stream = make_stream(deletes: ["items-1", "items-3"])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      remove_ops = Enum.filter(diff, fn op -> Enum.at(op, 0) == "remove" end)
      assert length(remove_ops) == 2
    end
  end

  describe "multiple stream assigns" do
    test "two stream assigns both appear in streams-diff" do
      stream_a = make_stream(inserts: [{"a-1", -1, %{id: 1, name: "A"}}])

      stream_b = %LiveStream{
        name: :songs,
        dom_id: fn item -> "songs-#{item.id}" end,
        inserts: [{"songs-1", -1, %{id: 1, title: "Song 1"}}],
        deletes: []
      }

      assigns = base_assigns() |> Map.put(:items, stream_a) |> Map.put(:songs, stream_b)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      paths = Enum.map(diff, fn op -> Enum.at(op, 1) end)
      assert Enum.any?(paths, &String.starts_with?(&1, "/items"))
      assert Enum.any?(paths, &String.starts_with?(&1, "/songs"))
    end
  end
end
