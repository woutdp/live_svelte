<script>
    import {preventDefault} from "svelte/legacy"
    import {fly} from "svelte/transition"
    import {elasticOut} from "svelte/easing"

    /** @type {{ messages: any, name: any, live: any }} */
    let {messages, name, live} = $props()

    let body = $state("")
    let messagesElement = $state()

    let charCount = $derived(body.length)

    $effect(() => {
        if (messagesElement) messagesElement.scroll({top: messagesElement.scrollHeight, behavior: "smooth"})
    })

    function submitMessage() {
        if (body === "") return
        live.pushEvent("send_message", {body})
        body = ""
    }
</script>

<div class="w-full flex flex-col items-center">
    <div
        class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-md flex flex-col sm:w-[360px] sm:max-w-none md:min-w-md"
    >
        <div class="card-body gap-0 p-0 flex flex-col min-h-0 flex-1 sm:h-[520px]">
            <div class="px-4 pt-4 pb-2">
                <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
                    {name}
                </span>
            </div>
            <ul bind:this={messagesElement} class="flex flex-col gap-3 flex-1 min-h-0 overflow-x-clip overflow-y-auto px-4 py-2">
                {#each messages as message (message.id)}
                    {@const me = message.name === name}
                    <li
                        in:fly={{x: 100 * (me ? 1 : -1), y: -20, duration: 1000, easing: elasticOut}}
                        class={me ? "chat chat-end" : "chat chat-start"}
                    >
                        <div in:fly={{y: 10}} class="chat-header text-xs text-base-content/60">{message.name}</div>
                        <div class={me ? "chat-bubble bg-brand text-white border-0" : "chat-bubble chat-bubble-neutral"}>
                            {message.body}
                        </div>
                    </li>
                {/each}
            </ul>

            <form onsubmit={preventDefault(submitMessage)} class="p-4 border-t border-base-300/50 bg-base-200/30 flex gap-2 items-center">
                <div class="relative flex-1 min-w-0">
                    <!-- svelte-ignore a11y_autofocus -->
                    <input
                        type="text"
                        name="message"
                        bind:value={body}
                        placeholder="Message…"
                        autofocus
                        autocomplete="off"
                        class="input input-bordered input-sm w-full pr-12 bg-base-100 border-base-300"
                        aria-label="Message"
                    />
                    <span class="absolute right-2 top-1/2 -translate-y-1/2 text-base-content/50 text-xs tabular-nums">
                        {charCount}
                    </span>
                </div>
                <button type="submit" class="btn btn-sm bg-brand text-white border-0 hover:opacity-90 shrink-0"> Send </button>
            </form>
        </div>
    </div>
</div>
