<script lang="ts">
    import {sharedCount, sharedCountIsOdd} from "./store"

    let {label, live}: {label: string; live: any} = $props()
</script>

<div class="card bg-base-100 shadow-lg border border-base-300/50 h-full">
    <div class="card-body gap-4 items-center text-center">
        <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
            {label}
        </span>

        <div class="flex items-center gap-6 py-2">
            <button
                class="btn btn-sm btn-outline border-base-300 hover:border-error hover:text-error"
                data-testid="store-decrement"
                onclick={() => sharedCount.update(n => n - 1)}
            >
                −1
            </button>

            <span class="text-4xl font-bold tabular-nums text-brand min-w-12" data-testid="store-count">
                {$sharedCount}
            </span>

            <button class="btn btn-sm btn-success border-0" data-testid="store-increment" onclick={() => sharedCount.update(n => n + 1)}>
                +1
            </button>
        </div>

        <span class="badge badge-sm badge-ghost">{$sharedCountIsOdd ? "Odd" : "Even"}</span>

        <div class="flex gap-2">
            <button class="btn btn-xs btn-ghost" data-testid="store-reset" onclick={() => sharedCount.set(0)}> Reset </button>
            <button
                class="btn btn-xs bg-brand text-white"
                data-testid="store-sync"
                onclick={() => live.pushEvent("sync_store", {value: $sharedCount})}
            >
                Sync to server
            </button>
        </div>
    </div>
</div>
