defmodule ExampleWeb.LiveSsr do
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    ssr_engine =
      case Application.get_env(:live_svelte, :ssr_module) do
        LiveSvelte.SSR.Deno -> "Deno"
        LiveSvelte.SSR.ViteJS -> "Vite (dev)"
        _ -> "Node.js"
      end

    {:ok, assign(socket, greeting: "Hello from the server!", ssr_engine: ssr_engine)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">SSR Demo</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        This component is rendered on the server using {@ssr_engine}. The initial HTML includes
        the Svelte output before the client-side JavaScript runs.
      </p>
      <.svelte name="SsrDemo" props={%{greeting: @greeting}} socket={@socket} ssr={true} />
    </div>
    """
  end
end
