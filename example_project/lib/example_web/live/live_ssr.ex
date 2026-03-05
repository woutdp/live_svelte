defmodule ExampleWeb.LiveSsr do
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, greeting: "Hello from the server!")}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">SSR Demo</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        This component is rendered on the server using NodeJS. The initial HTML includes
        the Svelte output before the client-side JavaScript runs.
      </p>
      <.svelte name="SsrDemo" props={%{greeting: @greeting}} socket={@socket} ssr={true} />
    </div>
    """
  end
end
