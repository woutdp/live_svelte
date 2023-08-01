<script>
    export let number
    export let live

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
