defmodule ExampleWeb.LiveNavigation do
  @moduledoc """
  LiveView demo for useLiveNavigation() composable and Link component.
  Demonstrates patch() and navigate() from Svelte without full page reloads.
  """
  use ExampleWeb, :live_view

  def mount(params, _session, socket) do
    page = params["page"] || "home"
    {:ok, assign(socket, page: page, query: %{})}
  end

  def handle_params(params, uri, socket) do
    query =
      case URI.parse(uri).query do
        nil -> %{}
        q -> URI.decode_query(q)
      end

    {:noreply, assign(socket, page: params["page"] || "home", query: query)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">Navigation (useLiveNavigation)</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Client-side navigation with <code>patch()</code> and <code>navigate()</code>
        from Svelte without full page reloads, plus the <code>Link</code> component.
      </p>
      <.svelte name="Navigation" props={%{page: @page, query: @query}} socket={@socket} ssr={false} />
    </div>
    """
  end
end
