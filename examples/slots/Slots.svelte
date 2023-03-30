<script>
    import {fly} from "svelte/transition"

    export let show = true
</script>

<button class="bg-black text-white p-2 rounded" on:click={() => (show = !show)}>Show/Hide</button>

{#if show}
    <div transition:fly|local={{y: 20}} class="flex flex-col gap-4">
        <div class="flex gap-2">
            <p>Inner Block:</p>
            <slot>Default</slot>
        </div>
        <div class="flex gap-2">
            <p>Updating named slot:</p>
            <slot name="the-slot-name">Another default</slot>
        </div>
    </div>
{/if}
