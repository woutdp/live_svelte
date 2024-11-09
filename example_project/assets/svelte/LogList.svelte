<script>
    import {preventDefault} from "svelte/legacy"

    import {slide, fly} from "svelte/transition"

    /** @type {{live: any, items?: any}} */
    let {live, items = []} = $props()
    let body = $state()
    let i = $state(1)
    let showItems = $state(true)

    function addItem() {
        if (!body) return
        live.pushEvent("add_item", {body})
        body = ""
    }
</script>

<div class="flex flex-col">
    <label>
        <input type="checkbox" bind:checked={showItems} />
        show list
    </label>

    <label>
        <input type="range" bind:value={i} max={items.length} />
        {i}
    </label>

    <div class="mb-2">
        <form>
            <input type="test" bind:value={body} class="border rounded px-2 py-1" />
            <button type="submit" class="bg-black rounded text-white px-2 py-1 font-bold" onclick={preventDefault(addItem)}>
                Add item
            </button>
        </form>
    </div>
</div>

{#if showItems}
    <div transition:fly={{x: -20}}>
        {#each items.slice(0, i) as item (item.id)}
            <div in:fly={{x: -40}}>
                <div transition:slide|local class="py-2 border-t border-[#eee]">
                    {item.id}: {item.body}
                </div>
            </div>
        {/each}
    </div>
{/if}
