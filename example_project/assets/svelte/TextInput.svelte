<script lang="ts">
    export let value: string
    export let name: string
    export let id: string
</script>

<div>
    <input
        type="text"
        {name}
        {id}
        bind:value
        class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-2
        sm:text-sm sm:leading-6 dark:bg-zinc-700 dark:text-zinc-100
        inlinedark:placeholder-zinc-300"
    />
</div>
