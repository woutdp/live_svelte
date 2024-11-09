<script>
    import {run, preventDefault} from "svelte/legacy"

    // https://github.com/tjenkinson/dynamic-marquee
    import {slide, fly} from "svelte/transition"
    import {Marquee} from "dynamic-marquee"
    import {onMount} from "svelte"

    /** @type {{news?: any, live: any}} */
    let {news = [], live} = $props()

    let newItem = $state("")
    let marquee = $state()
    let marqueeEl = $state()
    let index = 0
    let speed = $state(-150)

    function addItem() {
        if (newItem === "") return
        if (news.length === 0) marquee.appendItem(createItem(newItem))
        live.pushEvent("add_news_item", {body: newItem})
        newItem = ""
    }

    function removeItem(id) {
        live.pushEvent("remove_news_item", {id: id})
    }

    onMount(async () => {
        marquee = new Marquee(marqueeEl, {
            rate: speed,
            startOnScreen: false,
        })

        if (news.length > 0) marquee.appendItem(createItem(news[0].body))

        marquee.onItemRequired(() => {
            if (news.length === 0) return
            index += 1
            if (index > news.length - 1) index = 0
            return createItem(news[index].body)
        })
    })

    function createItem(text) {
        const item = document.createElement("span")
        item.classList.add("mx-8")
        item.classList.add("hover:text-black")
        item.textContent = text
        return item
    }

    run(() => {
        marquee && marquee.setRate(speed)
    })
</script>

<div class="flex flex-col w-full justify-center items-center h-[50vh]">
    <div>
        <div class="flex items-center">
            <form>
                <input class="rounded" type="text" bind:value={newItem} />
                <button class="bg-black text-white rounded px-2 py-1" onclick={preventDefault(addItem)} type="submit">Add Item</button>
            </form>
            <div class="ml-4">
                <button class="bg-black text-white rounded px-2 py-1 active:opacity-95" onclick={() => (speed -= 20)}>← Faster</button>
                <button class="bg-black text-white rounded px-2 py-1 active:opacity-95" onclick={() => (speed += 20)}>Slower →</button>
            </div>
        </div>

        <div class="flex flex-col gap-1 mt-2">
            {#each news as item (item.id)}
                <div in:fly={{y: 20}} out:slide={{y: -20}} class="mb-1">
                    <button class="bg-[#F00] px-2 py-1 rounded" onclick={() => removeItem(item.id)}>Remove</button>
                    {item.body}
                </div>
            {/each}
        </div>
    </div>
</div>

<div class="fixed bottom-0 left-0 text-white font-bold text-4xl z-20 p-4 rounded-r-lg bg-gradient-to-b from-[#f00] via-[#f77] to-[#f00]">
    BREAKING NEWS
</div>
<div
    bind:this={marqueeEl}
    class="fixed bottom-0 w-screen text-white font-bold text-xl py-2 bg-gradient-to-b from-[#f00] via-[#f77] to-[#f00]"
></div>
