<script>
  /**
   * @typedef {{ id: number, name: string, description: string, __dom_id: string }} Item
   * @type {{ items: Item[], live: any }}
   */
  let { items = [], live } = $props()

  let newName = $state("")
  let newDescription = $state("")

  function addItem() {
    if (!newName.trim()) return
    live.pushEvent("add_item", { name: newName, description: newDescription })
    newName = ""
    newDescription = ""
  }

  function removeItem(id) {
    live.pushEvent("remove_item", { id })
  }

  function clearStream() {
    live.pushEvent("clear_stream", {})
  }

  function resetStream() {
    live.pushEvent("reset_stream", {})
  }

  function resetStreamAt0() {
    live.pushEvent("reset_stream_at_0", {})
  }

  function updateItem(id) {
    live.pushEvent("update_item", { id })
  }

  function addCappedItem() {
    live.pushEvent("add_capped_item", {})
  }
</script>

<div class="card bg-base-100 shadow-lg border border-base-300/50">
  <div class="card-body gap-4">
    <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
      Svelte component (StreamDemo)
    </span>

    <!-- Add item form -->
    <div class="flex flex-col gap-2">
      <input
        class="input input-bordered input-sm"
        placeholder="Item name"
        data-testid="name-input"
        bind:value={newName}
      />
      <input
        class="input input-bordered input-sm"
        placeholder="Description"
        data-testid="description-input"
        bind:value={newDescription}
      />
      <button
        class="btn btn-sm btn-primary"
        data-testid="add-button"
        onclick={addItem}
        disabled={!newName.trim()}
      >
        Add Item
      </button>
    </div>

    <!-- Controls -->
    <div class="flex flex-wrap gap-2">
      <button class="btn btn-sm btn-outline" data-testid="clear-button" onclick={clearStream}>
        Clear All
      </button>
      <button class="btn btn-sm btn-outline" data-testid="reset-button" onclick={resetStream}>
        Reset (at: -1)
      </button>
      <button class="btn btn-sm btn-outline" data-testid="reset-button-at-0" onclick={resetStreamAt0}>
        Reset (at: 0)
      </button>
      <button class="btn btn-sm btn-secondary btn-outline" data-testid="add-capped-button" onclick={addCappedItem}>
        Add Capped (max 3)
      </button>
    </div>

    <!-- Item count -->
    <h3 class="font-semibold text-sm" data-testid="item-count">Items ({items.length})</h3>

    <!-- Items list -->
    {#if items.length === 0}
      <p class="text-sm text-base-content/50 italic" data-testid="empty-message">
        No items in the stream
      </p>
    {:else}
      <ul class="flex flex-col gap-2">
        {#each items as item (item.__dom_id)}
          <li
            class="flex items-center justify-between py-2 px-3 rounded-lg bg-base-200/60"
            data-testid="item-{item.id}"
          >
            <div>
              <span class="font-medium text-sm" data-testid="item-name-{item.id}">{item.name}</span>
              <span class="text-xs text-base-content/50 ml-2" data-testid="item-description-{item.id}">
                {item.description}
              </span>
              <span class="text-xs text-base-content/40 ml-2" data-testid="item-id-{item.id}">
                (id: {item.id})
              </span>
            </div>
            <button
              class="btn btn-xs btn-error btn-outline"
              data-testid="remove-{item.id}"
              onclick={() => removeItem(item.id)}
            >
              Remove
            </button>
            <button
              class="btn btn-xs btn-warning btn-outline"
              data-testid="update-{item.id}"
              onclick={() => updateItem(item.id)}
            >
              Update
            </button>
          </li>
        {/each}
      </ul>
    {/if}
  </div>
</div>
