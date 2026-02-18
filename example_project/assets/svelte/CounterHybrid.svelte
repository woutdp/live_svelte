<script>
    /** @type {{ number?: number }} */
    let {number = 1} = $props()
    let amount = $state(1)
</script>

<div class="flex flex-col justify-center items-center gap-4 p-4">
    <h2 class="text-center text-2xl font-light my-4">Plus / Minus (Hybrid)</h2>
    <p class="text-sm text-base-content/50 text-center max-w-sm">LiveView-driven value with phx-click; step amount is client state.</p>
    <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-xs md:min-w-md">
        <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Value </span>
            <div class="flex flex-row items-center justify-center gap-6 py-2">
                <button
                    class="btn btn-square btn-sm btn-outline border-base-300 hover:border-error hover:text-error"
                    phx-click="set_number"
                    value={number - amount}
                    aria-label="Decrease by {amount}"
                    data-testid="hybrid-plus-minus-minus"
                >
                    -{amount}
                </button>
                <span class="text-3xl font-bold tabular-nums text-brand min-w-[3rem] text-center" data-testid="hybrid-plus-minus-value">{number}</span>
                <button
                    class="btn btn-square btn-sm btn-success border-0"
                    phx-click="set_number"
                    value={number + amount}
                    aria-label="Increase by {amount}"
                    data-testid="hybrid-plus-minus-plus"
                >
                    +{amount}
                </button>
            </div>
            <label class="flex flex-col gap-1.5 mx-auto">
                <span class="text-xs font-medium text-base-content/50">Step amount</span>
                <input
                    type="number"
                    class="input input-bordered input-sm w-24 bg-base-200/50 border-base-300"
                    bind:value={amount}
                    min="1"
                    aria-label="Step amount"
                    data-testid="hybrid-plus-minus-step"
                />
            </label>
        </div>
    </div>
</div>
