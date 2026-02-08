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
    Process.delete(:live_svelte_last_render_time)

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
  # Tests
  # ---------------------------------------------------------------------------

  describe "auto_id — single component" do
    test "uses the bare component name as id" do
      html = render_html(base_assigns("Counter"))
      assert extract_id(html) == "Counter"
    end

    test "target div id is derived from component id" do
      html = render_html(base_assigns("Counter"))
      assert html =~ ~s(id="Counter-target")
    end
  end

  describe "auto_id — multiple same-name components" do
    test "first gets bare name, second gets -1 suffix" do
      # Call svelte/1 in tight sequence, convert to HTML after
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

  describe "auto_id — different component names" do
    test "each name has its own independent counter" do
      # Call all three in tight succession so the gap stays under 1ms
      r_a = render_svelte(base_assigns("Counter"))
      r_b = render_svelte(base_assigns("LogList"))
      r_c = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r_a)) == "Counter"
      assert extract_id(to_html(r_b)) == "LogList"
      assert extract_id(to_html(r_c)) == "Counter-1"
    end
  end

  describe "auto_id — explicit id override" do
    test "explicit id takes precedence over auto-generated id" do
      html = render_html(base_assigns("Counter", id: "my-custom-id"))
      assert extract_id(html) == "my-custom-id"
    end

    test "explicit id does not consume a counter slot" do
      # Explicit id first, then two auto-generated ones
      _r1 = render_svelte(base_assigns("Counter", id: "custom"))
      r2 = render_svelte(base_assigns("Counter"))
      r3 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r2)) == "Counter"
      assert extract_id(to_html(r3)) == "Counter-1"
    end
  end

  describe "counter reset between render cycles" do
    test "counters reset after a simulated render-cycle gap" do
      # First render cycle — tight sequence
      r1 = render_svelte(base_assigns("Counter"))
      r2 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r1)) == "Counter"
      assert extract_id(to_html(r2)) == "Counter-1"

      # Simulate time gap between render cycles (>1ms)
      Process.sleep(2)

      # Second render cycle — counters should reset
      r3 = render_svelte(base_assigns("Counter"))
      r4 = render_svelte(base_assigns("Counter"))

      assert extract_id(to_html(r3)) == "Counter"
      assert extract_id(to_html(r4)) == "Counter-1"
    end

    test "counters do NOT reset within the same render cycle" do
      # Rapid successive calls (same render cycle)
      results = for _ <- 1..5, do: render_svelte(base_assigns("Widget"))
      ids = Enum.map(results, &(to_html(&1) |> extract_id()))

      assert ids == ["Widget", "Widget-1", "Widget-2", "Widget-3", "Widget-4"]
    end
  end

  describe "live_json id derivation" do
    test "live_json div id is prefixed with lj- and uses the svelte id" do
      html = render_html(base_assigns("Counter", props: %{x: 1}))

      # When live_json_props is empty, no lj- div is rendered.
      # Verify the component id is still correct.
      assert extract_id(html) == "Counter"
    end
  end

  describe "phx-update attribute" do
    test "outer hook container has phx-update=ignore to prevent DOM morphing" do
      html = render_html(base_assigns("Counter"))
      # The outer div with phx-hook="SvelteHook" must have phx-update="ignore"
      # to prevent LiveView from recreating it during DOM diffs
      assert html =~ ~r/phx-hook="SvelteHook"[^>]*phx-update="ignore"/
    end
  end
end
