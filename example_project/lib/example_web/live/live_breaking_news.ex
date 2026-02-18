defmodule ExampleWeb.LiveBreakingNews do
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

    <div class="flex flex-col justify-center items-center gap-4 p-6 pb-40">
        <h2 class="text-center text-2xl font-light my-4">
            Breaking News
        </h2>
        <p class="text-sm text-base-content/50 text-center max-w-sm">
            Add headlines and control the ticker speed; remove items from the list.
        </p>

        <div class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-lg">
            <div class="card-body gap-4 p-5">
                <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
                    Headlines
                </span>

                <form class="flex flex-wrap gap-2">
                    <input
                        class="input input-bordered input-sm flex-1 min-w-0 bg-base-200/50 border-base-300"
                        type="text"
                        bind:value={newItem}
                        placeholder="New headline…"
                        aria-label="New headline"
                    />
                    <button class="btn btn-sm bg-brand text-white border-0 hover:opacity-90" onclick={preventDefault(addItem)} type="submit">
                        Add
                    </button>
                </form>

                <div class="flex items-center gap-2 flex-wrap">
                    <span class="text-xs font-medium text-base-content/50">Speed</span>
                    <button class="btn btn-sm btn-outline border-base-300 hover:border-brand hover:text-brand" onclick={() => (speed -= 20)}>← Faster</button>
                    <button class="btn btn-sm btn-outline border-base-300 hover:border-brand hover:text-brand" onclick={() => (speed += 20)}>Slower →</button>
                </div>

                <div class="border border-base-300/50 rounded-lg bg-base-200/30 overflow-hidden">
                    <ul class="max-h-48 overflow-auto divide-y divide-base-300/50">
                        {#each news as item (item.id)}
                            <li in:fly={{y: 20}} out:slide={{y: -20}} class="flex items-center justify-between gap-2 px-3 py-2 text-sm">
                                <span class="min-w-0 flex-1 truncate">{item.body}</span>
                                <button class="btn btn-sm btn-error btn-ghost hover:btn-error shrink-0" onclick={() => removeItem(item.id)} aria-label={"Remove #{item.body}"}>Remove</button>
                            </li>
                        {/each}
                    </ul>
                    {#if news.length === 0}
                        <div class="px-3 py-6 text-center text-sm text-base-content/50">No headlines yet.</div>
                    {/if}
                </div>
            </div>
        </div>
    </div>

    <div class="fixed bottom-0 left-0 text-white font-bold text-2xl sm:text-3xl z-20 px-4 py-3 rounded-r-lg bg-error shadow-lg" aria-hidden="true">
        BREAKING NEWS
    </div>
    <div
        bind:this={marqueeEl}
        data-testid="breaking-news-ticker"
        data-rate={speed}
        class="fixed bottom-0 w-screen text-white font-bold text-lg py-2 bg-error/90 shadow-inner"
        aria-hidden="true"
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
