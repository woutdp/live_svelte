# SSR Benchmark: Deno vs Node.js
#
# Part 1 — per-scenario latency: Deno vs NodeJS, single render. Benchee drives
#           one call at a time, so NodeJS pool_size is irrelevant here; this is
#           pure single-render latency. One Benchee run per scenario.
# Part 2 — concurrent throughput: sends a fixed burst of concurrent SSR
#           requests and cycles NodeJS through pool_size ∈ [4, 8, 12, 16].
#           Pool size only matters under concurrency; this part makes that
#           visible by saturating each pool.
# Part 3 — memory snapshot: queries actual V8/Deno process memory after
#           warmup renders (rss, heapUsed, heapTotal).
#
# Prerequisites:
#   mix deps.get && mix deps.compile
#
# Run:
#   mix run bench/ssr_benchmark.exs     # all parts
#   mix run bench/ssr_benchmark.exs 1   # latency only
#   mix run bench/ssr_benchmark.exs 2   # concurrent throughput only
#   mix run bench/ssr_benchmark.exs 3   # memory snapshot only
#
# Uses example_project/priv/svelte/server.js when present. Build once with:
#   cd example_project && mix assets.deploy
#
# Override:
#   LIVE_SVELTE_SERVER_JS=/path/to/priv/svelte mix run bench/ssr_benchmark.exs

# ---------------------------------------------------------------------------
# Locate server.js
# ---------------------------------------------------------------------------
example_svelte_dir = Path.expand("../example_project/priv/svelte", __DIR__)

fixture_js = ~S"""
function render(name, props, slots) {
  const propsEntries = Object.entries(props ?? {});
  const attrs = propsEntries
    .map(([k, v]) => `data-${k}="${String(v).replace(/"/g, "&quot;")}"`)
    .join(" ");
  const slotHtml = Object.values(slots ?? {}).join("");
  const body = Array.from({length: 20}, (_, i) =>
    `<li class="item-${i}">${name}-${i}: ${attrs.slice(0, 40)}</li>`
  ).join("\n");
  const html = `<div data-component="${name}" ${attrs}><ul>${body}</ul>${slotHtml}</div>`;
  // Must mirror the real render() contract: a plain {html, head, css} object.
  // The adapters return this value as-is (no JSON re-parse), so returning a
  // JSON string here would make render() yield a string and break ["html"].
  return { html, head: "", css: { code: "", map: null } };
}
function memoryUsage() {
  return JSON.stringify(process.memoryUsage());
}
if (typeof globalThis !== "undefined") {
  globalThis.render = render;
  globalThis.memoryUsage = memoryUsage;
}
export { render, memoryUsage };
"""

{server_dir, using_real_components} =
  cond do
    env = System.get_env("LIVE_SVELTE_SERVER_JS") ->
      IO.puts("[bench] Using custom server.js at #{env}")
      {env, false}

    File.exists?(Path.join(example_svelte_dir, "server.js")) ->
      IO.puts("[bench] Using example_project server.js at #{example_svelte_dir}")
      {example_svelte_dir, true}

    true ->
      dir = Path.join(System.tmp_dir!(), "live_svelte_bench_#{System.os_time(:second)}")
      File.mkdir_p!(dir)
      File.write!(Path.join(dir, "server.js"), fixture_js)
      IO.puts("[bench] No example_project build found — using fixture at #{dir}")
      IO.puts("[bench] Tip: cd example_project && mix assets.deploy")
      {dir, false}
  end

# ---------------------------------------------------------------------------
# Scenarios — {key, component_name, props, slots}
# ---------------------------------------------------------------------------
scenarios =
  if using_real_components do
    [
      {:hello_world, "HelloWorld", %{}, %{}},
      {:ssr_demo, "SsrDemo", %{"greeting" => "Benchmarking LiveSvelte SSR"}, %{}},
      {:static_component, "Static", %{"color" => "blue", "index" => 1}, %{}},
      {:simple_counter, "SimpleCounter", %{"number" => 42, "initialClientValue" => 0}, %{}},
      {:struct_display, "Struct",
       %{"struct" => %{"name" => "Alice", "age" => 30, "role" => "admin", "verified" => true}},
       %{}},
      {:log_list_50, "LogList",
       %{
         "live" => nil,
         "items" =>
           Enum.map(1..50, fn i -> %{"id" => i, "body" => "Benchmark log entry #{i}"} end)
       }, %{}}
    ]
  else
    [
      {:minimal, "Counter", %{"count" => 0}, %{}},
      {:simple_props, "Counter", %{"count" => 42, "label" => "clicks"}, %{}},
      {:large_list, "DataTable",
       %{
         "rows" =>
           Enum.map(1..50, fn i ->
             %{"id" => i, "name" => "Item #{i}", "value" => i * 1.5, "active" => rem(i, 2) == 0}
           end),
         "page" => 1,
         "total" => 50
       }, %{}},
      {:with_slots, "Modal", %{"title" => "Confirm action", "variant" => "warning"},
       %{
         "default" => "<p>Are you sure you want to delete this item?</p>",
         "footer" => "<button>Cancel</button><button>OK</button>"
       }}
    ]
  end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
defmodule Bench.Runtime do
  def start_nodejs(server_dir, pool_size) do
    case NodeJS.Supervisor.start_link(path: server_dir, pool_size: pool_size) do
      {:ok, pid} ->
        IO.puts("[bench] NodeJS supervisor started (pool_size: #{pool_size})")
        {:ok, pid}

      {:error, reason} ->
        IO.puts("[bench] WARNING: could not start NodeJS: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def stop_nodejs(pid) do
    ref = Process.monitor(pid)
    Supervisor.stop(pid, :normal, 5_000)

    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    after
      5_000 ->
        Process.exit(pid, :kill)
        :ok
    end
  end

  def start_deno(server_dir) do
    if Code.ensure_loaded?(DenoRider) do
      server_js = Path.join(server_dir, "server.js")

      case DenoRider.start_link(main_module_path: server_js) do
        {:ok, pid} ->
          IO.puts("[bench] DenoRider started")
          {:ok, pid}

        {:error, reason} ->
          IO.puts("[bench] WARNING: could not start Deno: #{inspect(reason)}")
          {:error, reason}
      end
    else
      IO.puts("[bench] Skipping Deno: add {:deno_rider, \"~> 0.2\"} to mix.exs")
      {:error, :not_available}
    end
  end
end

# Submits all `total` renders simultaneously so pool_size is the only bottleneck.
# Repeats `rounds` times and returns stats based on the median wall time.
defmodule Bench.Concurrent do
  def run(render_fn, total, rounds \\ 10) do
    wall_times =
      Enum.map(1..rounds, fn _ ->
        t0 = System.monotonic_time(:microsecond)

        1..total
        |> Task.async_stream(
          fn _ -> render_fn.() end,
          max_concurrency: total,
          timeout: 120_000,
          ordered: false
        )
        |> Stream.run()

        System.monotonic_time(:microsecond) - t0
      end)
      |> Enum.sort()

    median_us = Enum.at(wall_times, div(rounds, 2))
    best_us = List.first(wall_times)
    ops_per_sec = total * 1_000_000 / median_us

    {Float.round(median_us / 1_000, 1), Float.round(best_us / 1_000, 1),
     Float.round(ops_per_sec, 1)}
  end
end

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------
{:ok, _} = Application.ensure_all_started(:nodejs)

# Default NodeJS pool size = logical cores, matching how most apps size poolboy.
cores = System.schedulers_online()
IO.puts("[bench] Detected #{cores} logical cores (default NodeJS pool_size)")

deno_result = Bench.Runtime.start_deno(server_dir)
deno_available = match?({:ok, _}, deno_result)

node_result = Bench.Runtime.start_nodejs(server_dir, cores)

node_pid =
  case node_result do
    {:ok, pid} -> pid
    _ -> nil
  end

node_available = node_pid != nil

unless node_available or deno_available do
  IO.puts("\nNo SSR runtime could be started. Exiting.")
  System.halt(1)
end

sep = String.duplicate("=", 72)
bench_part = List.first(System.argv())

# ---------------------------------------------------------------------------
# Part 1 — per-scenario latency: Deno vs NodeJS (single render, serial)
# ---------------------------------------------------------------------------
if bench_part in [nil, "1"] do
  IO.puts("\n#{sep}")
  IO.puts("  Part 1: Per-Scenario SSR Latency — Deno vs NodeJS (single render)")
  IO.puts(sep)
  IO.puts("\n  Note: Benchee drives one render at a time, so NodeJS pool_size does")
  IO.puts("  NOT matter here — this is pure single-render latency. See Part 2 for")
  IO.puts("  how pool_size affects throughput under concurrency.")
  IO.puts("\n  Benchee memory_time measures BEAM heap allocation via GC tracing.")
  IO.puts("  V8/Deno process memory is NOT included. See Part 3 for runtime memory snapshots.\n")

  Enum.each(scenarios, fn {key, name, props, slots} ->
    jobs =
      [
        node_available &&
          {"NodeJS", fn -> LiveSvelte.SSR.NodeJS.render(name, props, slots) end},
        deno_available &&
          {"Deno", fn -> LiveSvelte.SSR.Deno.render(name, props, slots) end}
      ]
      |> Enum.filter(& &1)
      |> Map.new()

    IO.puts("\n--- #{key} (#{name}) ---\n")

    Benchee.run(
      jobs,
      time: 8,
      warmup: 2,
      memory_time: 2,
      formatters: [Benchee.Formatters.Console],
      print: [benchmarking: true, configuration: false, fast_warning: true]
    )
  end)
end

# ---------------------------------------------------------------------------
# Part 2 — concurrent throughput: NodeJS pool_size ∈ [4, 8, 12, 16]
#
# Sends `burst_concurrency` renders simultaneously and measures wall-clock
# throughput. Each pool worker handles one render at a time, so pool_size
# directly limits parallelism and its effect is visible here.
# ---------------------------------------------------------------------------
if bench_part in [nil, "2"] do
  pool_sizes = [4, 8, 12, 16]
  burst_total = 2000
  # Use the heaviest scenario to widen timing differences across pool sizes
  {_key, heavy_name, heavy_props, heavy_slots} = List.last(scenarios)
  node_render_fn = fn -> LiveSvelte.SSR.NodeJS.render(heavy_name, heavy_props, heavy_slots) end
  deno_render_fn = fn -> LiveSvelte.SSR.Deno.render(heavy_name, heavy_props, heavy_slots) end

  IO.puts("\n#{sep}")
  IO.puts("  Part 2: Concurrent Throughput — Deno vs NodeJS pool_size ∈ #{inspect(pool_sizes)}")
  IO.puts("  Component : #{heavy_name}")
  IO.puts("  Burst     : #{burst_total} renders all submitted simultaneously")
  IO.puts("  (NodeJS: pool_size is the concurrency limit via poolboy max_overflow=0)")
  IO.puts(sep)

  # Sanity check: one render of each runtime to confirm real work is happening
  IO.write("\n[bench] Sanity check NodeJS ... ")
  t_check = System.monotonic_time(:microsecond)
  sample = LiveSvelte.SSR.NodeJS.render(heavy_name, heavy_props, heavy_slots)

  IO.puts(
    "#{System.monotonic_time(:microsecond) - t_check}µs, #{String.length(sample["html"])} chars of HTML"
  )

  deno_result =
    if deno_available do
      IO.write("[bench] Sanity check Deno   ... ")
      t_check = System.monotonic_time(:microsecond)
      sample = LiveSvelte.SSR.Deno.render(heavy_name, heavy_props, heavy_slots)

      IO.puts(
        "#{System.monotonic_time(:microsecond) - t_check}µs, #{String.length(sample["html"])} chars of HTML"
      )

      IO.write("\n[bench] Warming up Deno ...")
      Bench.Concurrent.run(deno_render_fn, 32, 3)
      IO.puts(" done")

      IO.write("[bench] Measuring Deno (10 rounds) ...")
      result = Bench.Concurrent.run(deno_render_fn, burst_total)
      IO.puts(" done")
      result
    end

  nodejs_results =
    Enum.reduce(pool_sizes, {node_pid, []}, fn pool_size, {prev_pid, acc} ->
      if prev_pid, do: Bench.Runtime.stop_nodejs(prev_pid)

      case Bench.Runtime.start_nodejs(server_dir, pool_size) do
        {:ok, new_pid} ->
          IO.write("\n[bench] Warming up NodeJS pool=#{pool_size} ...")
          Bench.Concurrent.run(node_render_fn, pool_size * 4, 3)
          IO.puts(" done")

          IO.write("[bench] Measuring NodeJS pool=#{pool_size} (10 rounds) ...")
          result = Bench.Concurrent.run(node_render_fn, burst_total)
          IO.puts(" done")

          {new_pid, [{pool_size, result} | acc]}

        {:error, _} ->
          {prev_pid, acc}
      end
    end)
    |> then(fn {_, acc} -> Enum.reverse(acc) end)

  col = 16

  IO.puts("\n#{sep}")
  IO.puts("  Results  (#{burst_total} concurrent renders of #{heavy_name})")
  IO.puts(sep)

  header =
    String.pad_trailing("runtime", col) <>
      String.pad_leading("ops/sec", col) <>
      String.pad_leading("median ms", col) <>
      String.pad_leading("best ms", col)

  IO.puts("\n  #{header}")
  IO.puts("  #{String.duplicate("-", String.length(header))}")

  if deno_available && deno_result do
    {median_ms, best_ms, ops_sec} = deno_result

    IO.puts(
      "  " <>
        String.pad_trailing("Deno", col) <>
        String.pad_leading("#{ops_sec}", col) <>
        String.pad_leading("#{median_ms}", col) <>
        String.pad_leading("#{best_ms}", col)
    )
  end

  Enum.each(nodejs_results, fn {pool_size, {median_ms, best_ms, ops_sec}} ->
    IO.puts(
      "  " <>
        String.pad_trailing("NodeJS pool=#{pool_size}", col) <>
        String.pad_leading("#{ops_sec}", col) <>
        String.pad_leading("#{median_ms}", col) <>
        String.pad_leading("#{best_ms}", col)
    )
  end)

  IO.puts("")
end

# ---------------------------------------------------------------------------
# Part 3 — Memory Snapshot: query actual V8/Deno process memory
#
# Benchee's memory_time only measures BEAM heap allocation. This section
# queries the actual runtime memory from Node.js (process.memoryUsage) and
# Deno (Deno.memoryUsage) after a warmup batch.
# ---------------------------------------------------------------------------
if bench_part in [nil, "3"] do
  warmup_count = 100
  {_key, heavy_name, heavy_props, heavy_slots} = List.last(scenarios)

  IO.puts("\n#{sep}")
  IO.puts("  Part 3: Runtime Memory Snapshot")
  IO.puts("  (after #{warmup_count} warmup renders of #{heavy_name})")
  IO.puts(sep)

  memory_helper_path = Path.join(server_dir, "bench_memory.cjs")

  File.write!(memory_helper_path, """
  module.exports = { memoryUsage: () => process.memoryUsage() };
  """)

  node_pool_size = cores

  # In the full run, Part 2 leaves the pool at its last sweep size (e.g. 16).
  # Restart at a known pool size so the worker count we sample below matches
  # the ×node_pool_size total we report.
  if node_available do
    case Process.whereis(NodeJS.Supervisor) do
      nil -> :ok
      pid -> Bench.Runtime.stop_nodejs(pid)
    end

    Bench.Runtime.start_nodejs(server_dir, node_pool_size)
  end

  node_mem =
    if node_available do
      IO.write("\n[bench] Warming up NodeJS (#{warmup_count} renders) ...")

      Enum.each(1..warmup_count, fn _ ->
        LiveSvelte.SSR.NodeJS.render(heavy_name, heavy_props, heavy_slots)
      end)

      IO.puts(" done")
      IO.write("[bench] Querying NodeJS memory (#{node_pool_size} workers) ... ")

      # Fire pool_size calls concurrently, hoping each lands on a distinct
      # poolboy worker so we sample every process once. This is NOT guaranteed —
      # a fast worker can finish and serve a second call — so treat the
      # per-worker average as an approximation, not an exact per-process reading.
      samples =
        1..node_pool_size
        |> Task.async_stream(
          fn _ -> NodeJS.call!({"bench_memory.cjs", "memoryUsage"}, []) end,
          max_concurrency: node_pool_size,
          timeout: 10_000
        )
        |> Enum.map(fn {:ok, mem} -> mem end)

      avg_mem =
        samples
        |> Enum.reduce(%{"rss" => 0, "heapUsed" => 0, "heapTotal" => 0}, fn mem, acc ->
          %{
            "rss" => acc["rss"] + Map.get(mem, "rss", 0),
            "heapUsed" => acc["heapUsed"] + Map.get(mem, "heapUsed", 0),
            "heapTotal" => acc["heapTotal"] + Map.get(mem, "heapTotal", 0)
          }
        end)
        |> Map.new(fn {k, v} -> {k, div(v, length(samples))} end)

      IO.puts("ok")
      {avg_mem, samples}
    end

  File.rm(memory_helper_path)

  deno_mem =
    if deno_available do
      IO.write("[bench] Warming up Deno (#{warmup_count} renders) ...")

      Enum.each(1..warmup_count, fn _ ->
        LiveSvelte.SSR.Deno.render(heavy_name, heavy_props, heavy_slots)
      end)

      IO.puts(" done")
      IO.write("[bench] Querying Deno memory ... ")

      {:ok, mem} = DenoRider.eval("Deno.memoryUsage()")
      IO.puts("ok")
      mem
    end

  col = 16

  format_bytes = fn bytes ->
    mb = Float.round(bytes / 1_048_576, 2)
    "#{mb} MB"
  end

  IO.puts("\n#{sep}")
  IO.puts("  Runtime Memory (V8/Deno process heap)")
  IO.puts("  NodeJS: per-worker avg + total (#{node_pool_size} processes)")
  IO.puts("  Deno: single process")
  IO.puts(sep)

  header =
    String.pad_trailing("runtime", col) <>
      String.pad_leading("rss", col) <>
      String.pad_leading("heapUsed", col) <>
      String.pad_leading("heapTotal", col)

  IO.puts("\n  #{header}")
  IO.puts("  #{String.duplicate("-", String.length(header))}")

  if node_available && node_mem do
    {avg_mem, _samples} = node_mem
    rss = avg_mem["rss"]
    heap_used = avg_mem["heapUsed"]
    heap_total = avg_mem["heapTotal"]

    IO.puts(
      "  " <>
        String.pad_trailing("NodeJS (per)", col) <>
        String.pad_leading(format_bytes.(rss), col) <>
        String.pad_leading(format_bytes.(heap_used), col) <>
        String.pad_leading(format_bytes.(heap_total), col)
    )

    IO.puts(
      "  " <>
        String.pad_trailing("NodeJS (total)", col) <>
        String.pad_leading(format_bytes.(rss * node_pool_size), col) <>
        String.pad_leading(format_bytes.(heap_used * node_pool_size), col) <>
        String.pad_leading(format_bytes.(heap_total * node_pool_size), col)
    )
  end

  if deno_available && deno_mem do
    rss = Map.get(deno_mem, "rss", 0)
    heap_used = Map.get(deno_mem, "heapUsed", 0)
    heap_total = Map.get(deno_mem, "heapTotal", 0)

    IO.puts(
      "  " <>
        String.pad_trailing("Deno", col) <>
        String.pad_leading(format_bytes.(rss), col) <>
        String.pad_leading(format_bytes.(heap_used), col) <>
        String.pad_leading(format_bytes.(heap_total), col)
    )
  end

  IO.puts("")
end
