<script>
    /** @type {{ live: any, isOn?: boolean }} */
    let {live, isOn = $bindable(false)} = $props()
    const toggleLight = () => {
        isOn = !isOn
        live.pushEvent(isOn ? "on" : "off")
    }
</script>

<div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden">
    <div class="card-body gap-4 p-4">
        <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit"> Light </span>
        <div class="flex justify-between items-center gap-4">
            <label class="flex items-center gap-3 cursor-pointer">
                <input type="checkbox" class="toggle toggle-brand" checked={isOn} onchange={toggleLight} aria-label="Toggle light" />
                <span class="text-sm font-medium text-base-content/80">On / Off</span>
            </label>
            <div class="flex gap-2">
                <button
                    phx-click="down"
                    class="btn btn-square btn-outline btn-sm border-base-300 hover:border-brand hover:text-brand"
                    aria-label="Decrease brightness"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-5 h-5"
                    >
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                    </svg>
                </button>
                <button
                    phx-click="up"
                    class="btn btn-square btn-outline btn-sm border-base-300 hover:border-brand hover:text-brand"
                    aria-label="Increase brightness"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-5 h-5"
                    >
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5" />
                    </svg>
                </button>
            </div>
        </div>
    </div>
</div>

<style>
    /* Brand color for toggle (DaisyUI v5), scoped to this component */
    .toggle-brand:checked {
        --input-color: var(--color-brand);
    }
</style>
