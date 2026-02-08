<script lang="ts">
    import * as _ from "lodash"

    interface Props {
        unordered: number[]
    }

    let {unordered}: Props = $props()
    let ordered = _.sortBy(unordered)
</script>

<h1 class="text-center text-2xl font-light my-4">Lodash Demo</h1>
<p class="text-sm text-base-content/50 mb-8 text-center">Using npm packages with Svelte in a regular non LiveView page.</p>
<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden md:min-w-md">
    <div class="card-body gap-4 p-5">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Lodash · TypeScript </span>
        <h2 class="text-lg font-semibold text-brand">Sorted with lodash</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1">
                <span class="text-xs text-base-content/50 font-medium">Unordered</span>
                <pre class="font-mono text-sm bg-base-200/80 text-base-content p-3 rounded-lg border border-base-300/50"><code
                        >[{unordered.join(", ")}]</code
                    ></pre>
            </div>
            <div class="flex flex-col gap-1">
                <span class="text-xs text-base-content/50 font-medium">Ordered</span>
                <pre class="font-mono text-sm bg-base-200/80 text-base-content p-3 rounded-lg border border-base-300/50"><code
                        >[{ordered.join(", ")}]</code
                    ></pre>
            </div>
        </div>
    </div>
</div>
