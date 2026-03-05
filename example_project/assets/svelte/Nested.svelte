<script lang="ts">
    // import Child from "./Child.svelte"
    let {children}: { children?: import("svelte").Snippet } = $props()
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden md:w-md p-5">
    <h3 class="badge badge-outline badge-sm font-medium text-base-content/70">Parent Svelte component</h3>
    <div class="card-body">
        <!-- <Child onClick={() => alert("Event triggered in child and handled in parent")} /> -->
        <div class="mt-5">
            <h5 class="badge badge-outline badge-sm font-medium text-base-content/70">Slot Item</h5>
            {@render children?.()}
        </div>
    </div>
</div>
