<script>
    import {slide, fly} from "svelte/transition"

    export let pushEvent
    export let items = []

    let newItemName
    let i = 1
    let showItems = true

    function addItem() {
        if (!newItemName) return
        pushEvent("add_item", {name: newItemName})
        newItemName = ""
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
            <input type="test" bind:value={newItemName} class="border rounded px-2 py-1" />
            <button type="submit" on:click|preventDefault={addItem} class="bg-black rounded text-white px-2 py-1 font-bold">Add item</button
            >
        </form>
    </div>
</div>

{#if showItems}
    <div transition:fly={{x: -20}}>
        {#each items.slice(0, i) as item (item.id)}
            <div in:fly={{x: -40}}>
                <div transition:slide|local class="py-2 border-t border-[#eee]">
                    {item.id}: {item.name}
                </div>
            </div>
        {/each}
    </div>
{/if}
