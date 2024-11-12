<script lang="ts">
    let {children, subtitle}: Props = $props()
</script>

<i>Opening</i>
<hr class="mb-2" />

<p>{@render children?.()}</p>
{#if subtitle}
    <h1 class="text-2xl">Svelte Subtitle</h1>
    {@render subtitle?.()}
{/if}

<hr class="mt-2" />
<i>Closing</i>
