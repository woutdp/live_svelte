<script lang="ts">
    import {useEventReply} from "live_svelte"

    const {data, isLoading, execute, cancel} = useEventReply<{result: number; input: number}, {value: number}>("compute")

    let inputValue = $state(21)
</script>

<div data-testid="event-reply-container" class="w-full max-w-md mx-auto card bg-base-100 shadow-md border border-base-300/50">
    <div class="card-body gap-4">
        <h3 class="card-title text-base">Request-Response Demo</h3>

        <div class="form-control">
            <label class="label" for="value-input">
                <span class="label-text">Input value</span>
            </label>
            <input id="value-input" data-testid="value-input" type="number" bind:value={inputValue} class="input input-bordered" />
        </div>

        <div class="flex gap-2">
            <button
                data-testid="compute-btn"
                onclick={() => execute({value: inputValue})}
                disabled={$isLoading}
                class="btn bg-brand text-white border-0 hover:opacity-90 flex-1"
            >
                {$isLoading ? "Computing..." : "Compute ×2"}
            </button>
            <button data-testid="cancel-btn" onclick={() => cancel()} disabled={!$isLoading} class="btn btn-ghost"> Cancel </button>
        </div>

        {#if $data}
            <div data-testid="reply-result" class="alert">
                <span>
                    Result: <span data-testid="result-value" class="font-bold">{$data.result}</span>
                    (input was {$data.input})
                </span>
            </div>
        {/if}
    </div>
</div>
