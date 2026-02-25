<script lang="ts">
    import { useLiveSvelte } from "live_svelte"
    import TextInput from "./TextInput.svelte"

    let { items }: { items: string[] } = $props()
    const { pushEvent } = useLiveSvelte()

    let inputValue = $state("")

    function handleSubmit(e: SubmitEvent) {
        e.preventDefault()
        if (!inputValue.trim()) return
        pushEvent("add-item", { name: inputValue })
        inputValue = ""
    }
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full min-w-xs">
    <div class="card-body gap-4 p-5">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
            Component composition
        </span>

        <form onsubmit={handleSubmit} class="flex flex-col gap-2">
            <TextInput
                bind:value={inputValue}
                name="item"
                id="item-input"
                data-testid="composition-input"
            />
            <button
                data-testid="composition-submit"
                type="submit"
                class="btn btn-sm bg-brand text-white border-0 hover:opacity-90"
            >
                Add item
            </button>
        </form>

        {#if items.length > 0}
            <ul class="flex flex-col gap-1">
                {#each items as item}
                    <li data-testid="composition-item" class="text-sm px-3 py-2 rounded bg-base-200">
                        {item}
                    </li>
                {/each}
            </ul>
        {/if}
    </div>
</div>
