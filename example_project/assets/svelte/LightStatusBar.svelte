<script>
    import {tweened} from "svelte/motion"
    import {cubicOut} from "svelte/easing"
    export let brightness = 0

    const progress = tweened(0, {
        duration: 400,
        easing: cubicOut,
    })

    const updateProgress = b => progress.set(b / 100)

    $: updateProgress(brightness)
</script>

<progress class="border-none w-full rounded-lg h-12" value={$progress} />
<div class="h-12 rounded-md w-full font-mono font-semibold">
    <div class="text-center w-full flex items-center justify-center h-full">
        {brightness > 0 ? `${brightness}%` : "OFF"}
    </div>
</div>

<style>
    :root {
        --progColor: linear-gradient(to right, hsl(6, 100%, 80%), hsl(356, 100%, 65%));
        --progHeight: 20px;
    }

    progress,
    progress::-webkit-progress-value {
        width: 100%;
        border: 0;
        height: var(--progHeight);
        border-radius: 20px;
        background: var(--progColor);
    }
    progress::-webkit-progress-bar {
        width: 100%;
        border: 0;
        height: var(--progHeight);
        border-radius: 20px;
        background: white;
    }

    progress::-moz-progress-bar {
        width: 100%;
        border: 0;
        height: var(--progHeight);
        border-radius: 20px;
        background: var(--progColor);
    }
</style>
