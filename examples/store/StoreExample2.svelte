<script>
    import store from "./store"
</script>

<label>
    <input type="checkbox" bind:checked={$store} />
    {$store}
</label>
