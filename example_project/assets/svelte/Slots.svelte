<script lang="ts">
    interface Props {
        children?: import("svelte").Snippet
        subtitle?: import("svelte").Snippet
    }
    let {children, subtitle}: Props = $props()
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-md min-w-md">
    <div class="card-body gap-4 p-5">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Slots </span>
        <div class="text-sm text-base-content/50 italic">Opening</div>
        <div class="border-t border-base-300/50 pt-2">
            <div class="text-base-content/90">
                {@render children?.()}
            </div>
        </div>
        {#if subtitle}
            <div class="border-t border-base-300/50 pt-3 space-y-2">
                <h3 class="text-lg font-semibold text-base-content/80">Svelte subtitle</h3>
                <div class="text-base-content/90">
                    {@render subtitle?.()}
                </div>
            </div>
        {/if}
        <div class="border-t border-base-300/50 pt-2 text-sm text-base-content/50 italic">Closing</div>
    </div>
</div>
