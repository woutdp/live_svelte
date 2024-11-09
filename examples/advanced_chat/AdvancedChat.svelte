<script>
    import {preventDefault} from "svelte/legacy"
    import {slide, fly, fade} from "svelte/transition"
    import {elasticOut} from "svelte/easing"

    /** @type {{messages: any, name: any, live: any}} */
    let {messages, name, live} = $props()

    let body = $state("")
    let messagesElement = $state()

    $effect(() => {
        scrollToBottom(messagesElement)
    })

    const scrollToBottom = async node => {
        node.scroll({top: node.scrollHeight, behavior: "smooth"})
    }

    function submitMessage() {
        if (body === "") return
        live.pushEvent("send_message", {body})
        body = ""
    }
</script>

<div in:fade class="flex flex-col justify-between items-between sm:border sm:rounded-lg w-full h-full sm:w-[360px] sm:h-[600px]">
    <ul bind:this={messagesElement} class="flex flex-col gap-2 h-full sm:h-[400px] overflow-x-clip overflow-y-auto p-2">
        {#each messages as message (message.id)}
            {@const me = message.name === name}
            <li
                in:fly={{x: 100 * (me ? 1 : -1), y: -20, duration: 1000, easing: elasticOut}}
                class="
          rounded-[1em] px-4 py-2 flex flex-col
          {me ? 'rounded-tr-none ml-10 bg-[#0A80FE] text-white' : 'rounded-tl-none mr-10 bg-[#E9E8EB] text-black'}
        "
            >
                <span in:fly={{y: 10}} class="text-xs font-bold">{message.name}</span>
                <span in:fade>{message.body}</span>
            </li>
        {/each}
    </ul>

    <form onsubmit={preventDefault(submitMessage)} class="bg-gray-100 p-2 flex gap-2">
        <!-- svelte-ignore a11y_autofocus -->
        <input
            type="text"
            name="message"
            class="flex-grow rounded-full bg-transparent text-black"
            bind:value={body}
            placeholder="Message..."
            autofocus
            autocomplete="off"
        />
        <button class="bg-black text-white rounded px-4 py-2">Send</button>
    </form>
</div>
