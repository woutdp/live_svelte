defmodule ExampleWeb.LiveSsr do
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, greeting: "Hello from the server!")}
  end

  def render(assigns) do
    ~H"""
    <.demo_page title="SSR Demo" tag="h2" variant="compact">
      <:description>
        This component is rendered on the server using NodeJS. The initial HTML includes
        the Svelte output before the client-side JavaScript runs.
      </:description>
      <.svelte name="SsrDemo" props={%{greeting: @greeting}} socket={@socket} ssr={true} />
    </.demo_page>
    """
  end
end
