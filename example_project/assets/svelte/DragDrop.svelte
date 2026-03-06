<script lang="ts">
    import {dndzone} from "svelte-dnd-action"

    let {items, live} = $props()
    let localItems = $derived(items)

    function handleConsider(e) {
        localItems = e.detail.items
    }

    function handleFinalize(e) {
        localItems = e.detail.items
        live.pushEvent("reorder", {ids: localItems.map(i => i.id)})
    }
    $inspect(items)
</script>

<div use:dndzone={{items: localItems}} onconsider={handleConsider} onfinalize={handleFinalize} class="flex flex-col gap-2">
    {#each localItems as item (item.id)}
        <div data-testid="drag-item" class="card bg-base-200 border border-base-300 cursor-grab active:cursor-grabbing select-none">
            <div class="card-body py-3 px-4 flex-row items-center gap-3">
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-4 h-4 text-base-content/30 shrink-0"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        d="M8 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm0 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm0 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm8-12a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm0 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm0 6a2 2 0 1 1-4 0 2 2 0 0 1 4 0z"
                    />
                </svg>
                <span data-testid="drag-item-name" class="text-sm font-medium">{item.name}</span>
            </div>
        </div>
    {/each}
</div>
