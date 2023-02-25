defmodule LiveSvelte do
  @moduledoc ~S'''

  ## Examples

  ### LiveView

      defmodule App.SvelteLive do
        use App, :live_view

        def render(assigns) do
          ~H"""
          <.live_component
            module={LiveSvelte}
            id="Example"
            name="Example"
            props={%{items: @items, i: @i, showItems: @show_items}}
          />
          """
        end

        def handle_event("add_item", %{"name" => name}, socket) do
          socket =
            socket
            |> assign(:items, socket.assigns.items ++ [name])
            |> assign(:i, length(socket.assigns.items) + 1)
            |> assign(:show_items, true)

          {:noreply, socket}
        end

        def mount(_params, _session, socket) do
          {:ok,
           socket
           |> assign(:items, ["One", "Two", "Three", "Four", "Five"])
           |> assign(:i, 3)
           |> assign(:show_items, true)}
        end
      end

  ### Svelte Component

      <script>
          import {slide, fly} from 'svelte/transition'

          export let pushEvent
          export let i = 5
          export let items = []
          export let showItems = true

          let newItemName

          function addItem() {
              pushEvent('add_item', {name: newItemName})
              newItemName = ''
          }
      </script>

      <div class="flex flex-col">
          <label>
              <input type="checkbox" bind:checked={showItems}>
              show list
          </label>

          <label>
              <input type="range" bind:value={i} max={items.length}>
          </label>

          <div class="mb-2">
              <input type="test" bind:value={newItemName} class="border rounded px-2 py-1"/>
              <button on:click={addItem} class="bg-black rounded text-white px-2 py-1">Add item</button>
          </div>
      </div>

      {#if showItems}
          <div transition:fly={{x: -20}}>
              {#each items.slice(0, i) as item}
                  <div transition:slide|local class="py-2 border-t border-[#eee]">
                      {item}
                  </div>
              {/each}
          </div>
      {/if}
  '''

  use Phoenix.LiveComponent
  import Phoenix.HTML

  attr(:props, :map, default: %{})
  attr(:name, :string)
  attr(:rendered, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <div>
      <%!-- TODO: This can return things like <title> which should be in the head --%>
      <%!-- <script><%= raw(@ssr_render["head"]) %></script> --%>
      <style><%= raw(@ssr_render["css"]["code"]) %></style>
      <div
        id={id(@name)}
        data-name={@name}
        data-props={json(@props)}
        phx-update="ignore"
        phx-hook="SvelteComponent"
      >
        <%= raw(@ssr_render["html"]) %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    # Maybe something like this?
    # socket = if not Map.get(assigns, :rendered, false) do
    #   send self(), {:rendered, true}
    # end

    socket =
      socket
      |> assign(assigns)
      # TODO: Only render once
      |> assign(:ssr_render, ssr_render(assigns.name, assigns[:props]))

    {:ok, socket}
  end

  def ssr_render(name, props \\ %{}) do
    NodeJS.call!({"svelte/render", "render"}, [name, props])
  end

  defp json(props) do
    props
    |> Jason.encode()
    |> case do
      {:ok, encoded} -> encoded
      {:error, _} -> ""
    end
  end

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"
end
