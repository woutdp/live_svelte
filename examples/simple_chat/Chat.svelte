<script>
    import {preventDefault} from "svelte/legacy"

    import {slide} from "svelte/transition"

    /** @type {{messages: any, live: any}} */
    let {messages, live} = $props()

    let message = $state("")
    let name = $state("")

    function submitMessage() {
        if (message === "" || name === "") return
        live.pushEvent("send_message", {body: message, name: name})
        message = ""
    }
</script>

<div class="flex flex-col justify-between items-between min-h-[400px]">
    <ul class="flex flex-col gap-2">
        {#each messages as message (message.id)}
            <li in:slide class="bg-[#eee] rounded-full px-4 py-2 rounded-bl-none">
                <i>{message.name}:</i>
                {message.body}
            </li>
        {/each}
    </ul>

    <form onsubmit={preventDefault(submitMessage)}>
        <input type="text" name="name" class="rounded" bind:value={name} placeholder="Your Name" />
        <input type="text" name="message" class="rounded" bind:value={message} placeholder="Message..." />
        <button class="bg-black text-white rounded px-4 py-2">Send</button>
    </form>
</div>
