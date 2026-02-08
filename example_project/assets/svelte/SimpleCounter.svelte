<script>
    /** @type {{number: any}} */
    let {number} = $props()
    let other = $state(1)
</script>

<svelte:head>
    <title>Simple Counter</title>
</svelte:head>

<div class="min-h-[50vh] flex flex-col justify-center items-center p-6 bg-base-200/40">
    <h1 class="text-2xl font-semibold text-base-content/80 mb-8 tracking-tight">Simple Counter</h1>

    <div class="flex flex-wrap justify-center gap-8">
        <!-- Server counter card -->
        <div class="card bg-base-100 shadow-lg border border-base-300/50 w-52">
            <div class="card-body items-center text-center gap-4 py-6">
                <span class="badge badge-outline badge-sm font-medium text-base-content/70">Server</span>
                <span class="text-4xl font-bold tabular-nums text-brand">{number}</span>
                <button class="btn btn-sm bg-brand text-white border-0 hover:opacity-90" phx-click="increment"> +1 </button>
            </div>
        </div>

        <!-- Client counter card -->
        <div class="card bg-base-100 shadow-lg border border-base-300/50 w-52">
            <div class="card-body items-center text-center gap-4 py-6">
                <span class="badge badge-outline badge-sm font-medium text-base-content/70">Client</span>
                <span class="text-4xl font-bold tabular-nums text-success">{other}</span>
                <button class="btn btn-sm btn-success border-0" onclick={() => (other += 1)}> +1 </button>
            </div>
        </div>
    </div>

    <p class="mt-8 text-sm text-base-content/50 max-w-sm text-center">Server state updates via LiveView; client state updates locally.</p>
</div>
