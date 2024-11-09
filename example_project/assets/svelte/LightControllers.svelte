<script>
    /** @type {{live: any, isOn?: boolean}} */
    let {live, isOn = $bindable(false)} = $props()
    const toggleLight = () => {
        isOn = !isOn
        live.pushEvent(isOn ? "on" : "off")
    }
</script>

<div class="my-2 flex justify-between items-center">
    <button
        type="button"
        class={`${
            isOn ? "bg-brand" : "bg-gray-200"
        } relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2`}
        role="switch"
        aria-checked="false"
        aria-label="Use setting"
        onclick={toggleLight}
    >
        <span class="sr-only">Use setting</span>
        <span
            aria-hidden="true"
            class={`${
                isOn ? "translate-x-5" : "translate-x-0"
            } pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out`}
        >
        </span>
    </button>
    <div class="flex gap-2">
        <button
            phx-click="down"
            class="flex items-center justify-center text-xl font-bold w-10 h-10 p-2 rounded bg-slate-100 hover:bg-brand active:bg-brand shadow-md hover:shadow-xl"
            aria-label="down"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
            >
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
            </svg>
        </button>
        <button
            phx-click="up"
            class="flex items-center justify-center text-xl font-bold w-10 h-10 p-2 rounded bg-slate-100 hover:bg-brand active:bg-brand shadow-md hover:shadow-xl"
            aria-label="up"
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
            >
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5" />
            </svg>
        </button>
    </div>
</div>
