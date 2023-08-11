<script>
    import {getLive} from "live_svelte"

    const live = getLive()

    export let number

    function increase() {
        live.pushEvent("set_number", {number: number + 1})
    }

    function decrease() {
        live.pushEvent("set_number", {number: number - 1})
    }
</script>

<h1>Component is working</h1>
<p>The number is {number}</p>

<button on:click={increase}>+</button>
<button on:click={decrease}>-</button>
