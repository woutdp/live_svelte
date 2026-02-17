<script>
    import {run} from "svelte/legacy"
    import {tweened} from "svelte/motion"
    import {cubicOut} from "svelte/easing"

    /** @type {{ brightness?: number }} */
    let {brightness = 0} = $props()

    const progress = tweened(0, {
        duration: 400,
        easing: cubicOut,
    })

    const updateProgress = b => progress.set(b / 100)

    run(() => {
        updateProgress(brightness)
    })
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden md:min-w-md">
    <div class="card-body gap-3 p-4">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Brightness </span>
        <progress class="progress progress-brand border-0 w-full rounded-full h-3 bg-base-200" value={$progress} max="1"></progress>
        <div class="flex items-center justify-center min-h-10">
            <span class="font-mono text-lg font-semibold tabular-nums {brightness > 0 ? 'text-brand' : 'text-base-content/50'}" data-testid="light-brightness-value">
                {brightness > 0 ? `${brightness}%` : "OFF"}
            </span>
        </div>
    </div>
</div>

<style>
    .progress-brand {
        color: var(--color-brand);
    }
    .progress-brand::-webkit-progress-value {
        background-color: var(--color-brand);
    }
    .progress-brand::-moz-progress-bar {
        background-color: var(--color-brand);
    }
</style>
