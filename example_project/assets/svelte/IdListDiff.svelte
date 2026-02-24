<script>
  /** @type {{ items: Array<{id: number, name: string}> }} */
  let { items = [] } = $props();
</script>

<div class="card bg-base-100 shadow-lg border border-base-300/50">
  <div class="card-body gap-3 p-4">
    <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
      Svelte component
    </span>
    {#if items.length === 0}
      <p class="text-sm text-base-content/50 italic" data-testid="empty-list">No items</p>
    {:else}
      <ul class="flex flex-col gap-2" data-testid="item-list">
        {#each items as item (item.id)}
          <li
            data-testid="item-{item.id}"
            class="flex items-center gap-3 py-2 px-3 rounded-lg bg-base-200/60"
          >
            <span class="text-xs text-base-content/40 font-mono w-6 text-right">{item.id}</span>
            <span class="font-medium" data-testid="item-name-{item.id}">{item.name}</span>
          </li>
        {/each}
      </ul>
    {/if}
    <p class="text-xs text-base-content/50 mt-1">
      {items.length} item{items.length === 1 ? "" : "s"}
    </p>
  </div>
</div>
