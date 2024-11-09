<script>
    /** @type {{children?: import('svelte').Snippet}} */
    let {children} = $props()
</script>

<p>Before slot</p>
<p>{@render children?.()}</p>
<p>After slot</p>
