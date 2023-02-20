<script>
    export let number = 1;
    export let pushEvent;
    
    function increase() {
        pushEvent('set_number', { number: number + 1 })
    }
    
    function decrease() {
        pushEvent('set_number', { number: number - 1 })
    }
</script>

<h1 class="text-red">Component is working</h1>
<p>The number is {number}</p>

<button on:click={increase}>+</button>
<button on:click={decrease}>-</button>
