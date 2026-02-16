defmodule LiveSvelte.AutoIdTest do
  # Must be synchronous — tests depend on process dictionary state.
  use ExUnit.Case, async: false

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp base_assigns(name, opts \\ []) do
    %{
      __changed__: nil,
      socket: nil,
      name: name,
      id: Keyword.get(opts, :id),
      key: Keyword.get(opts, :key),
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

  defp extract_id(html) do
    # The first id="..." after phx-hook="SvelteHook" is the component's own id.
    # But simpler: the first id attribute on a div with data-name is ours.
    case Regex.run(~r/id="([^"]+)"[^>]*data-name=/, html) do
      [_, id] -> id
      _ -> nil
    end
  end

  # Call svelte/1 to assign the ID (fast), defer HTML conversion for later.
  defp render_svelte(assigns) do
    LiveSvelte.svelte(assigns)
  end

  defp to_html(rendered) do
    rendered |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp clear_auto_id_state do
    Process.get_keys()
    |> Enum.each(fn
      {:live_svelte_counter, _} = k -> Process.delete(k)
      _ -> :ok
    end)
  end

  setup do
    clear_auto_id_state()
    on_exit(&clear_auto_id_state/0)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Tests — counter fallback (no identity in props)
  # ---------------------------------------------------------------------------

  describe "counter fallback — single component without identity props" do
    test "uses the bare component name as id" do
      html = render_html(base_assigns("Counter"))
      assert extract_id(html) == "Counter"
    end

    test "target div id is derived from component id" do
      html = render_html(base_assigns("Counter"))
      assert html =~ ~s(id="Counter-target")
    end
  end

  describe "counter fallback — multiple same-name components without identity props" do
    test "first gets bare name, second gets -1 suffix" do
      r1 = render_svelte(base_assigns("Counter"))
      r2 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r1)) == "Counter"
      assert extract_id(to_html(r2)) == "Counter-1"
    end

    test "third instance gets -2 suffix" do
      _r1 = render_svelte(base_assigns("Counter"))
      _r2 = render_svelte(base_assigns("Counter"))
      r3 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r3)) == "Counter-2"
    end
  end

  describe "counter fallback — different component names" do
    test "each name has its own independent counter" do
      r_a = render_svelte(base_assigns("Counter"))
      r_b = render_svelte(base_assigns("LogList"))
      r_c = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r_a)) == "Counter"
      assert extract_id(to_html(r_b)) == "LogList"
      assert extract_id(to_html(r_c)) == "Counter-1"
    end
  end

  # ---------------------------------------------------------------------------
  # Tests — explicit id override
  # ---------------------------------------------------------------------------

  describe "explicit id override" do
    test "explicit id takes precedence over auto-generated id" do
      html = render_html(base_assigns("Counter", id: "my-custom-id"))
      assert extract_id(html) == "my-custom-id"
    end

    test "explicit id takes precedence over key attribute" do
      html = render_html(base_assigns("Counter", id: "my-custom-id", key: 42))
      assert extract_id(html) == "my-custom-id"
    end

    test "explicit id takes precedence over identity props" do
      html = render_html(base_assigns("Counter", id: "my-custom-id", props: %{index: 5}))
      assert extract_id(html) == "my-custom-id"
    end

    test "explicit id does not consume a counter slot" do
      _r1 = render_svelte(base_assigns("Counter", id: "custom"))
      r2 = render_svelte(base_assigns("Counter"))
      r3 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r2)) == "Counter"
      assert extract_id(to_html(r3)) == "Counter-1"
    end
  end

  # ---------------------------------------------------------------------------
  # Tests — key attribute
  # ---------------------------------------------------------------------------

  describe "key attribute" do
    test "key generates name-key id" do
      html = render_html(base_assigns("Static", key: 0))
      assert extract_id(html) == "Static-0"
    end

    test "key takes precedence over identity props" do
      html = render_html(base_assigns("Static", key: "mykey", props: %{index: 99}))
      assert extract_id(html) == "Static-mykey"
    end

    test "string key works" do
      html = render_html(base_assigns("Card", key: "abc-123"))
      assert extract_id(html) == "Card-abc-123"
    end

    test "key does not consume a counter slot" do
      _r1 = render_svelte(base_assigns("Widget", key: 0))
      r2 = render_svelte(base_assigns("Widget"))

      # Widget without key/identity falls back to counter — gets bare name
      assert extract_id(to_html(r2)) == "Widget"
    end
  end

  # ---------------------------------------------------------------------------
  # Tests — identity auto-detection from props
  # ---------------------------------------------------------------------------

  describe "identity from props — :index key" do
    test "props with atom :index key generate deterministic id" do
      html = render_html(base_assigns("Static", props: %{index: 0, color: "red"}))
      assert extract_id(html) == "Static-0"
    end

    test "each loop item gets a unique stable id" do
      results =
        for i <- 0..3 do
          render_svelte(base_assigns("Static", props: %{index: i, color: "red"}))
        end

      ids = Enum.map(results, &(to_html(&1) |> extract_id()))
      assert ids == ["Static-0", "Static-1", "Static-2", "Static-3"]
    end

    test "ids are stable even when only one item is rendered (simulates LiveView partial re-render)" do
      # First render: items 0, 1, 2
      batch1 =
        for i <- 0..2 do
          render_svelte(base_assigns("Static", props: %{index: i, color: "red"}))
        end

      ids1 = Enum.map(batch1, &(to_html(&1) |> extract_id()))
      assert ids1 == ["Static-0", "Static-1", "Static-2"]

      # Simulate LiveView only rendering the NEW item (index 3)
      # — this is the scenario that broke the old counter approach
      r_new = render_svelte(base_assigns("Static", props: %{index: 3, color: "red"}))
      assert extract_id(to_html(r_new)) == "Static-3"

      # No conflict with existing ids — "Static-3" is unique
    end
  end

  describe "identity from props — :id key" do
    test "props with atom :id key generate deterministic id" do
      html = render_html(base_assigns("UserCard", props: %{id: "user-42", name: "Alice"}))
      assert extract_id(html) == "UserCard-user-42"
    end
  end

  describe "identity from props — string keys" do
    test "props with string \"index\" key generate deterministic id" do
      html = render_html(base_assigns("Item", props: %{"index" => 7}))
      assert extract_id(html) == "Item-7"
    end

    test "props with string \"id\" key generate deterministic id" do
      html = render_html(base_assigns("Item", props: %{"id" => "abc"}))
      assert extract_id(html) == "Item-abc"
    end
  end

  describe "identity from props — priority order" do
    test ":id takes precedence over :index" do
      html = render_html(base_assigns("Card", props: %{id: "x", index: 5}))
      assert extract_id(html) == "Card-x"
    end

    test ":key in props takes precedence over :index" do
      html = render_html(base_assigns("Card", props: %{key: "k", index: 5}))
      assert extract_id(html) == "Card-k"
    end
  end

  describe "identity from props — no identity keys" do
    test "falls back to counter when props have no identity keys" do
      r1 = render_svelte(base_assigns("Chart", props: %{data: [1, 2, 3], type: "line"}))
      r2 = render_svelte(base_assigns("Chart", props: %{data: [4, 5, 6], type: "bar"}))

      assert extract_id(to_html(r1)) == "Chart"
      assert extract_id(to_html(r2)) == "Chart-1"
    end

    test "falls back to counter when props is empty" do
      r1 = render_svelte(base_assigns("Widget"))
      r2 = render_svelte(base_assigns("Widget"))

      assert extract_id(to_html(r1)) == "Widget"
      assert extract_id(to_html(r2)) == "Widget-1"
    end
  end

  # ---------------------------------------------------------------------------
  # Tests — live_json and phx-update (unchanged from before)
  # ---------------------------------------------------------------------------

  describe "live_json id derivation" do
    test "live_json div id is prefixed with lj- and uses the svelte id" do
      html = render_html(base_assigns("Counter", props: %{x: 1}))

      # When live_json_props is empty, no lj- div is rendered.
      # Verify the component id is still correct.
      assert extract_id(html) == "Counter"
    end
  end

  describe "phx-update attribute" do
    test "inner target div has phx-update=ignore to protect Svelte content" do
      html = render_html(base_assigns("Counter"))
      # The inner data-svelte-target div must have phx-update="ignore"
      # to protect Svelte's rendered DOM from LiveView's morphdom patching
      assert html =~ ~r/data-svelte-target[^>]*phx-update="ignore"/
    end

    test "outer hook container does NOT have phx-update=ignore" do
      html = render_html(base_assigns("Counter"))
      # The outer div must NOT have phx-update="ignore" so LiveView can
      # manage it in comprehensions (for loops) — add, remove, reorder
      refute html =~ ~r/phx-hook="SvelteHook"[^>]*phx-update="ignore"/
    end
  end
end
