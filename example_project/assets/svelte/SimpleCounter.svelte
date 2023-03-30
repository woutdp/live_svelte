<script>
    export let number
    let other = 1
</script>

<svelte:head>
    <title>Simple Counter</title>
</svelte:head>

<div class="flex flex-col justify-center items-center gap-4 p-4">
    <div class="flex flex-row items-center justify-center gap-10">
        <div class="flex flex-col justify-center items-center">
            Server
            <span class="text-xl">{number}</span>
            <button class="plus" phx-click="increment">+1</button>
        </div>

        <div class="flex flex-col justify-center items-center">
            Client
            <span class="text-xl">{other}</span>
            <button class="plus" on:click={() => (other += 1)}>+1</button>
        </div>
    </div>
</div>
