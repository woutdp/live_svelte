<script>
    import { preventDefault } from "svelte/legacy";
    import { slide, fly } from "svelte/transition";

    /** @type {{ live: any, items?: any }} */
    let { live, items = [] } = $props();
    let body = $state("");
    let i = $state(1);
    let showItems = $state(true);

    function addItem() {
        if (!body) return;
        live.pushEvent("add_item", { body });
        body = "";
    }

    $effect(() => {
        if (i > items.length && items.length > 0) i = items.length;
    });
</script>

<div class="flex flex-col justify-center items-center gap-4 p-4">
    <h2 class="text-center text-2xl font-light my-4">
        Log stream
    </h2>
    <p class="text-sm text-base-content/50 text-center max-w-sm">
        Add items or let the timer append entries; limit how many are shown.
    </p>

    <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-lg">
        <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
                Log list
            </span>

            <div class="flex flex-wrap items-center gap-4">
                <label class="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" class="checkbox checkbox-sm checkbox-primary" bind:checked={showItems} />
                    <span class="text-sm text-base-content/80">Show list</span>
                </label>
                <label class="flex items-center gap-2">
                    <span class="text-xs font-medium text-base-content/50 whitespace-nowrap">Show last</span>
                    <input
                        type="range"
                        class="range range-primary range-sm w-32"
                        bind:value={i}
                        max={items.length || 1}
                        min="1"
                    />
                    <span class="text-sm font-mono tabular-nums w-6">{i}</span>
                </label>
            </div>

            <form class="flex gap-2 flex-wrap">
                <input
                    type="text"
                    bind:value={body}
                    class="input input-bordered input-sm flex-1 min-w-0 bg-base-200/50 border-base-300"
                    placeholder="Type and add…"
                    aria-label="New log entry"
                />
                <button
                    type="submit"
                    class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
                    onclick={preventDefault(addItem)}
                >
                    Add item
                </button>
            </form>

            {#if showItems}
                <div class="border border-base-300/50 rounded-lg bg-base-200/30 overflow-hidden" transition:fly={{ x: -20 }}>
                    <ul class="max-h-64 overflow-auto divide-y divide-base-300/50">
                        {#each items.slice(0, i) as item (item.id)}
                            <li in:fly={{ x: -40 }} out:fly={{ x: 20 }}>
                                <div transition:slide|local class="px-3 py-2 text-sm font-mono text-base-content/90">
                                    <span class="text-base-content/50">{item.id}:</span> {item.body}
                                </div>
                            </li>
                        {/each}
                    </ul>
                    {#if items.length === 0}
                        <div class="px-3 py-6 text-center text-sm text-base-content/50">
                            No entries yet. Add one above or wait for the timer.
                        </div>
                    {/if}
                </div>
            {/if}
        </div>
    </div>
</div>
