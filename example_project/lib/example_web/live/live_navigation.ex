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
    <.demo_page title="Navigation (useLiveNavigation)" tag="h2" variant="compact">
      <:description>
        Client-side navigation with <code>patch()</code>
        and <code>navigate()</code>
        from Svelte without full page reloads, plus the <code>Link</code>
        component.
      </:description>
      <.svelte name="Navigation" props={%{page: @page, query: @query}} socket={@socket} />
    </.demo_page>
    """
  end
end
