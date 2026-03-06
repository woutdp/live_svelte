<script lang="ts">
  import { Debounced, ElementSize, PressedKeys } from "runed"

  let { items, matches, lastSize, comboCount, live } = $props()

  // ── 1. Debounced search ──────────────────────────────────────────────────────
  let query = $state("")
  const debounced = new Debounced(() => query, 400)

  $effect(() => {
    live.pushEvent("search", { query: debounced.current })
  })

  // ── 2. ElementSize ───────────────────────────────────────────────────────────
  let el = $state<HTMLElement>()
  const size = new ElementSize(() => el)
  const debouncedWidth = new Debounced(() => size.width, 300)
  const debouncedHeight = new Debounced(() => size.height, 300)

  $effect(() => {
    if (debouncedWidth.current > 0) {
      live.pushEvent("resize", {
        width: debouncedWidth.current,
        height: debouncedHeight.current,
      })
    }
  })

  // ── 3. PressedKeys ───────────────────────────────────────────────────────────
  const keys = new PressedKeys()
  keys.onKeys(["Control", "Enter"], () => live.pushEvent("combo", {}))
</script>

<!-- Section 1: Debounced search -->
<div class="flex flex-col gap-6">
  <div>
    <p class="text-xs font-semibold text-base-content/40 uppercase tracking-wider mb-3">
      Debounced
    </p>
    <input
      type="text"
      bind:value={query}
      placeholder="Search languages..."
      data-testid="search-input"
      class="input input-bordered w-full text-sm"
    />
    <div class="flex gap-4 mt-2 text-xs text-base-content/50">
      <span>Typing: <span data-testid="typed-value" class="font-mono">{query}</span></span>
      <span>Debounced: <span data-testid="debounced-value" class="font-mono">{debounced.current}</span></span>
    </div>
    <ul data-testid="matches-list" class="mt-3 flex flex-wrap gap-1">
      {#each matches as item}
        <li class="badge badge-ghost text-xs">{item}</li>
      {/each}
    </ul>
  </div>

  <div class="divider my-0"></div>

  <!-- Section 2: ElementSize -->
  <div>
    <p class="text-xs font-semibold text-base-content/40 uppercase tracking-wider mb-3">
      ElementSize
    </p>
    <textarea
      bind:this={el}
      data-testid="resizable-element"
      class="textarea textarea-bordered w-full min-h-[80px] resize text-sm"
      placeholder="Resize me! My dimensions sync to the server."
    ></textarea>
    <p class="text-xs text-base-content/50 mt-1">
      Live: <span data-testid="live-size" class="font-mono">{size.width}×{size.height}px</span>
    </p>
  </div>

  <div class="divider my-0"></div>

  <!-- Section 3: PressedKeys -->
  <div>
    <p class="text-xs font-semibold text-base-content/40 uppercase tracking-wider mb-3">
      PressedKeys
    </p>
    <div data-testid="pressed-keys" class="flex flex-wrap gap-1 min-h-[28px]">
      {#each [...keys.all] as key}
        <kbd class="kbd kbd-sm">{key}</kbd>
      {/each}
      {#if keys.all.size === 0}
        <span class="text-xs text-base-content/30 italic">Hold any keys...</span>
      {/if}
    </div>
    <p class="text-xs text-base-content/50 mt-2">
      Press <kbd class="kbd kbd-xs">Ctrl</kbd>+<kbd class="kbd kbd-xs">Enter</kbd>
      to increment the server counter (current: <span data-testid="combo-display">{comboCount}</span>)
    </p>
  </div>
</div>
