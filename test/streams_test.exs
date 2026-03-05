# Struct used to test @derive {LiveSvelte.Encoder, only: [...]} in stream items.
# Must be defined at file level (compile-time) for @derive to work.
defmodule LiveSvelte.StreamsTest.SecretItem do
  @derive {LiveSvelte.Encoder, only: [:id, :name]}
  defstruct [:id, :name, :secret]
end

defmodule LiveSvelte.StreamsTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.LiveStream
  alias LiveSvelte.StreamsTest.SecretItem

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
      replace_op =
        Enum.find(diff, fn op -> Enum.at(op, 0) == "replace" && Enum.at(op, 1) == "/items" end)

      assert replace_op != nil
      assert Enum.at(replace_op, 2) == []

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op != nil
      assert Enum.at(upsert_op, 1) == "/items/-"

      # Order matters: replace MUST come before upsert so the array exists before items are inserted
      replace_idx =
        Enum.find_index(diff, fn op ->
          Enum.at(op, 0) == "replace" && Enum.at(op, 1) == "/items"
        end)

      upsert_idx = Enum.find_index(diff, fn op -> Enum.at(op, 0) == "upsert" end)

      assert replace_idx < upsert_idx,
             "replace [] must precede upsert ops (got replace at #{replace_idx}, upsert at #{upsert_idx})"
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

    test "4-tuple insert with non-nil limit emits limit op" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Alice"}, 10}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      limit_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "limit" end)
      assert limit_op != nil, "expected limit op"
      assert Enum.at(limit_op, 1) == "/items"
      assert Enum.at(limit_op, 2) == 10
    end

    test "4-tuple insert with nil limit does not emit limit op" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Alice"}, nil}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      limit_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "limit" end)
      assert limit_op == nil, "must not emit limit op when limit is nil"
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

  describe "struct encoding in stream items" do
    test "struct with @derive only: [...] does not expose restricted fields in upsert value" do
      item = %SecretItem{id: 1, name: "Alice", secret: "hidden_password"}
      stream = make_stream(inserts: [{"items-1", -1, item}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op != nil, "expected upsert op"
      value = Enum.at(upsert_op, 2)

      assert value["id"] == 1
      assert value["name"] == "Alice"
      assert value["__dom_id"] == "items-1"
      refute Map.has_key?(value, "secret"), "sensitive field must not appear in stream diff"
    end

    test "struct encoding does not lose __dom_id even when only: [...] is used" do
      item = %SecretItem{id: 42, name: "Bob", secret: "top_secret"}
      stream = make_stream(inserts: [{"items-42", -1, item}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      value = Enum.at(upsert_op, 2)
      assert value["__dom_id"] == "items-42", "__dom_id must always be present"
    end

    test "plain map stream items still work after encoder integration" do
      item = %{id: 99, name: "Plain", extra: "visible"}
      stream = make_stream(inserts: [{"items-99", -1, item}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      value = Enum.at(upsert_op, 2)
      assert value["id"] == 99
      assert value["name"] == "Plain"
      assert value["extra"] == "visible"
      assert value["__dom_id"] == "items-99"
    end
  end

  describe "5-tuple inserts (update_only)" do
    test "update_only: true generates replace op at $$dom_id path" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "Updated"}, nil, true}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      replace_op =
        Enum.find(diff, fn op ->
          Enum.at(op, 0) == "replace" && String.contains?(Enum.at(op, 1) || "", "$$items-1")
        end)

      assert replace_op != nil, "expected replace op at $$dom_id path for update_only: true"
      assert Enum.at(replace_op, 1) == "/items/$$items-1"

      # Must NOT generate upsert for update_only: true
      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op == nil, "must NOT generate upsert when update_only: true"
    end

    test "update_only: false with 5-tuple generates upsert op" do
      stream = make_stream(inserts: [{"items-2", -1, %{id: 2, name: "New"}, nil, false}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      upsert_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "upsert" end)
      assert upsert_op != nil, "expected upsert op when update_only: false"
      assert Enum.at(upsert_op, 1) == "/items/-"
    end

    test "5-tuple with limit emits limit op" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "A"}, 5, false}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      limit_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "limit" end)
      assert limit_op != nil, "expected limit op"
      assert Enum.at(limit_op, 1) == "/items"
      assert Enum.at(limit_op, 2) == 5
    end

    test "5-tuple with nil limit does not emit limit op" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "A"}, nil, false}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      limit_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "limit" end)
      assert limit_op == nil, "must not emit limit op when limit is nil"
    end

    test "5-tuple with negative limit emits negative limit op (keep last N)" do
      stream = make_stream(inserts: [{"items-1", -1, %{id: 1, name: "A"}, -3, false}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      limit_op = Enum.find(diff, fn op -> Enum.at(op, 0) == "limit" end)
      assert limit_op != nil, "expected limit op"
      assert Enum.at(limit_op, 1) == "/items"
      assert Enum.at(limit_op, 2) == -3
    end

    test "update_only: true value includes __dom_id" do
      stream = make_stream(inserts: [{"items-5", -1, %{id: 5, name: "X"}, nil, true}])
      assigns = base_assigns() |> Map.put(:items, stream)
      html = render_html(assigns)
      diff = decode_streams_diff(html)

      replace_op =
        Enum.find(diff, fn op ->
          Enum.at(op, 0) == "replace" && String.contains?(Enum.at(op, 1) || "", "$$items-5")
        end)

      value = Enum.at(replace_op, 2)
      assert value["__dom_id"] == "items-5"
      assert value["id"] == 5
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
