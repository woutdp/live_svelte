<script>
  /** @type {{ a: number, b: number, c: number, label?: string }} */
  let { a = 0, b = 0, c = 0, label = "" } = $props();
</script>

<div class="card bg-base-100 border border-base-300/50 shadow-md overflow-hidden">
  <div class="card-body gap-3 p-4">
    {#if label}
      <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
        {label}
      </span>
    {/if}
    <div class="flex flex-wrap gap-4 items-center">
      <div class="flex items-center gap-2">
        <span class="text-xs text-base-content/50">A</span>
        <span data-testid="props-diff-value-a" class="font-mono font-bold tabular-nums text-brand">{a}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-xs text-base-content/50">B</span>
        <span data-testid="props-diff-value-b" class="font-mono font-bold tabular-nums text-brand">{b}</span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-xs text-base-content/50">C</span>
        <span data-testid="props-diff-value-c" class="font-mono font-bold tabular-nums text-brand">{c}</span>
      </div>
    </div>
  </div>
</div>
