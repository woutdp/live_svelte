<script>
    /** @type {{number?: number}} */
    let {number = 1} = $props()
    let amount = $state(1)
</script>

<div class="flex flex-col justify-center items-center gap-4">
    <div class="flex flex-row items-center justify-center gap-10">
        <button class="minus" phx-click="set_number" value={number - amount}>-{amount}</button>
        <span class="text-xl">{number}</span>
        <button class="plus" phx-click="set_number" value={number + amount}>+{amount}</button>
    </div>
    <label>
        Amount:
        <input type="number" class="rounded" bind:value={amount} min="1" />
    </label>
</div>

<style>
    button {
        background-color: black;
        color: white;
        padding: 0.5rem 1rem;
        border-radius: 0.25rem;
        font-weight: bold;
    }

    button.minus {
        background-color: red;
    }

    button.plus {
        background-color: rgb(0, 190, 0);
    }
</style>
