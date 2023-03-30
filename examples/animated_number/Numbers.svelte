<script>
    import {fly} from "svelte/transition"

    export let number = 1
    export let pushEvent

    function increase() {
        pushEvent("set_number", {number: number + 1})
    }

    function decrease() {
        pushEvent("set_number", {number: number - 1})
    }
</script>

<h1 class="text-lg mb-6">Component is working, and the number should be animated</h1>

<button on:click={increase} class="bg-black text-white px-4 py-2 rounded-lg font-bold">+</button>
<button on:click={decrease} class="bg-black text-white px-4 py-2 rounded-lg font-bold">-</button>

{#key number}
    <p class="mt-1">
        The number is:
        <br />
        <span in:fly={{y: -40}} class="absolute px-2 mt-2" style="font-size: {number / 2}rem;">
            {number}
        </span>
    </p>
{/key}
