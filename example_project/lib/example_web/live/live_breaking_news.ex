defmodule ExampleWeb.LiveExample5 do
  use ExampleWeb, :live_view

  @initial_news [
    %{id: 1, body: "Giant Pink Elephant Sighted Downtown"},
    %{id: 2, body: "Local Cat Becomes Mayor of Small Town"},
    %{id: 3, body: "Scientists Discover New Flavor of Ice Cream"},
    %{
      id: 4,
      body: "World's Largest Pizza Baked in Local Pizzeria, Still Not Big Enough for Customers"
    },
    %{
      id: 5,
      body:
        "Clown Epidemic Sweeps Through Town, Everyone Laughs Until They Realize the Clowns Aren't Joking"
    }
  ]

  def render(assigns) do
    ~V"""
    <script>
        import { run, preventDefault } from 'svelte/legacy';

        import {slide, fly} from "svelte/transition"
        import {Marquee} from "dynamic-marquee"
        import {onMount} from "svelte"

        /** @type {{news?: any, live: any}} */
        let { news = [], live } = $props();

        let newItem = $state("")
        let marquee = $state()
        let marqueeEl = $state()
        let index = 0
        let speed = $state(-150)

        // Function to add a new item to the news feed
        function addItem() {
            if (newItem === "") return
            if (news.length === 0) marquee.appendItem(createItem(newItem))
            live.pushEvent("add_news_item", {body: newItem})
            newItem = ""
        }

        // Function to remove an item from the news feed
        function removeItem(id) {
            live.pushEvent("remove_news_item", {id: id})
        }

        // Run this code when the component is mounted to the DOM
        onMount(async () => {
            // Create a new Marquee instance
            marquee = new Marquee(marqueeEl, {
                rate: speed,
                startOnScreen: false,
            })

            // Add the first item to the Marquee, if there is one
            if (news.length > 0) marquee.appendItem(createItem(news[0].body))

            // Add an item to the Marquee whenever it is required
            marquee.onItemRequired(() => {
                if (news.length === 0) return
                index += 1
                if (index > news.length - 1) index = 0
                return createItem(news[index].body)
            })
        })

        // Function to create a new Marquee item
        function createItem(text) {
            const item = document.createElement("span")
            item.classList.add("mx-8")
            item.classList.add("hover:text-black")
            item.textContent = text
            return item
        }

        // Set the Marquee speed whenever it is changed
        run(() => {
            marquee && marquee.setRate(speed)
        });
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
    >
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :news, @initial_news)}
  end

  def handle_event("remove_news_item", %{"id" => id}, socket) do
    updated_news = Enum.reject(socket.assigns.news, fn item -> item.id == id end)
    {:noreply, assign(socket, :news, updated_news)}
  end

  def handle_event("add_news_item", %{"body" => body}, socket) do
    new_item = %{id: System.unique_integer([:positive]), body: body}
    updated_news = socket.assigns.news ++ [new_item]
    {:noreply, assign(socket, :news, updated_news)}
  end
end
