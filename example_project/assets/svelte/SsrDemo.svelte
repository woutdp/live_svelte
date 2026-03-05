<script>
    let {greeting} = $props()

    let clicks = $state(0)
</script>

<div class="card bg-base-100 border border-base-300 p-6 max-w-sm text-center space-y-4">
    <p data-testid="ssr-greeting" class="text-lg">{greeting}</p>
    <p class="text-sm text-base-content/50">This text was rendered by the server before JavaScript loaded.</p>
    <div class="flex items-center justify-center gap-4">
        <button data-testid="ssr-increment" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 w-fit" onclick={() => clicks++}>
            Click me !!!
        </button>
        <span data-testid="click-count" class="font-mono">{clicks}</span>
    </div>
    <p class="text-xs text-base-content/30">Click counter is client-side only (not SSR)</p>
</div>
