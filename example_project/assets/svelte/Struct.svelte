<script>
    let { struct } = $props();
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden">
    <div class="card-body gap-4 p-5">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
            Struct
        </span>
        <pre class="font-mono text-sm bg-base-200/80 text-base-content p-4 rounded-lg border border-base-300/50 overflow-x-auto"><code>{JSON.stringify(struct, null, 2)}</code></pre>
        <button
            phx-click="randomize"
            class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 w-fit"
        >
            Randomize Age
        </button>
    </div>
</div>
