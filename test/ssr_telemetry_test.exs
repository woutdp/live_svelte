defmodule LiveSvelte.SSRTelemetryTest do
  # must be synchronous — modifies global config and attaches telemetry handlers
  use ExUnit.Case, async: false

  alias LiveSvelte.SSR

  # Named handler to avoid telemetry "local function" performance penalty log warning.
  # test_pid is threaded through the telemetry config argument.
  def handle_telemetry(event, measurements, metadata, test_pid) do
    send(test_pid, {:telemetry_event, event, measurements, metadata})
  end

  defmodule MockSSRRenderer do
    @moduledoc false
    @behaviour SSR

    @impl true
    def render("Success", _props, _slots) do
      %{"head" => "", "html" => "<div>Hello</div>"}
    end

    def render("Failing", _props, _slots) do
      raise RuntimeError, "SSR render failed"
    end

    # Catch-all: prevents unhelpful FunctionClauseError on typos in test component names
    def render(name, _props, _slots) do
      raise "MockSSRRenderer: no handler for #{inspect(name)}"
    end
  end

  setup do
    original_module = Application.get_env(:live_svelte, :ssr_module)
    Application.put_env(:live_svelte, :ssr_module, MockSSRRenderer)

    test_pid = self()
    handler_id = {__MODULE__, :telemetry_test, make_ref()}

    :telemetry.attach_many(
      handler_id,
      [
        [:live_svelte, :ssr, :start],
        [:live_svelte, :ssr, :stop],
        [:live_svelte, :ssr, :exception]
      ],
      &__MODULE__.handle_telemetry/4,
      test_pid
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)

      if original_module do
        Application.put_env(:live_svelte, :ssr_module, original_module)
      else
        Application.delete_env(:live_svelte, :ssr_module)
      end
    end)

    :ok
  end

  describe "SSR telemetry" do
    test "emits :start event with component, props, and slots metadata" do
      props = %{"count" => 42}
      slots = %{"default" => "<span>slot content</span>"}

      SSR.render("Success", props, slots)

      assert_receive {:telemetry_event, [:live_svelte, :ssr, :start], _measurements, metadata}
      assert metadata.component == "Success"
      assert metadata.props == %{"count" => 42}
      assert metadata.slots == %{"default" => "<span>slot content</span>"}
    end

    test "emits :stop event with duration measurement and passes through render result" do
      result = SSR.render("Success", %{}, %{})

      assert result == %{"head" => "", "html" => "<div>Hello</div>"}
      assert_receive {:telemetry_event, [:live_svelte, :ssr, :stop], measurements, metadata}
      assert metadata.component == "Success"
      assert is_integer(measurements.duration)
      assert measurements.duration >= 0
    end

    test "emits :exception event with metadata and duration when renderer raises" do
      assert_raise RuntimeError, "SSR render failed", fn ->
        SSR.render("Failing", %{}, %{})
      end

      assert_receive {:telemetry_event, [:live_svelte, :ssr, :exception], measurements, metadata}
      assert metadata.component == "Failing"
      assert is_integer(measurements.duration)
      assert measurements.duration >= 0
    end

    test "emits independent telemetry events for each render call" do
      SSR.render("Success", %{"call" => 1}, %{})
      SSR.render("Success", %{"call" => 2}, %{})

      assert_receive {:telemetry_event, [:live_svelte, :ssr, :start], _,
                      %{component: "Success", props: %{"call" => 1}}}

      assert_receive {:telemetry_event, [:live_svelte, :ssr, :start], _,
                      %{component: "Success", props: %{"call" => 2}}}
    end
  end
end
