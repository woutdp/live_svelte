<script>
    /** @type {{ big_data_set: any }} */
    let {big_data_set} = $props()

    let keyCount = $derived(Object.keys(big_data_set).length)
    let byteSize = $derived(JSON.stringify(big_data_set).length)
</script>

<div class="flex flex-col gap-3">
    <p class="text-xs text-base-content/50">Check the WebSocket to see how much data is transferred.</p>
    <dl class="flex flex-col gap-2">
        <div class="flex justify-between items-center gap-4 text-sm">
            <dt class="text-base-content/60">Key length</dt>
            <dd data-testid="live-json-key-count" class="font-mono font-semibold tabular-nums text-brand">{keyCount.toLocaleString()}</dd>
        </div>
        <div class="flex justify-between items-center gap-4 text-sm">
            <dt class="text-base-content/60">Rough byte size</dt>
            <dd data-testid="live-json-byte-size" class="font-mono font-semibold tabular-nums text-brand">{byteSize.toLocaleString()}</dd>
        </div>
    </dl>
    <button data-testid="live-json-remove-element" phx-click="remove_element" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 w-fit mt-1"> Remove element </button>
</div>
