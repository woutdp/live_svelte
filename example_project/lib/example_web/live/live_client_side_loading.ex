defmodule ExampleWeb.LiveClientSideLoading do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 data-testid="client-side-loading-heading" class="text-center text-2xl font-light my-4">
        Client-side loading
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Use the loading slot when SSR is disabled; the slot shows until the component hydrates on the client.
      </p>

      <div class="flex flex-col sm:flex-row flex-wrap justify-center gap-6 w-full max-w-3xl">
        <section data-testid="client-side-loading-client-section" class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-sm">
          <div class="card-body gap-4 p-5">
            <span class="badge badge-ghost badge-sm font-medium text-base-content/70 w-fit">
              Client side
            </span>
            <p class="text-xs text-base-content/50">Recommended: no SSR, loading slot shown until hydrated.</p>
            <.svelte name="ClientSideLoading" ssr={false}>
              <:loading>
                <div class="flex items-center gap-2 py-4">
                  <span class="loading loading-spinner loading-sm text-brand"></span>
                  <span class="text-sm text-base-content/60">Loading…</span>
                </div>
              </:loading>
            </.svelte>
          </div>
        </section>

        <section data-testid="client-side-loading-server-section" class="card bg-base-100 shadow-md border border-base-300/50 overflow-hidden w-full max-w-sm border-warning/50">
          <div class="card-body gap-4 p-5">
            <span class="badge badge-warning badge-sm font-medium w-fit">
              Server side (avoid)
            </span>
            <p class="text-xs text-base-content/50 italic">May flicker and log a console warning.</p>
            <.svelte name="ClientSideLoading" socket={@socket}>
              <:loading>
                <div class="flex items-center gap-2 py-4">
                  <span class="loading loading-spinner loading-sm text-brand"></span>
                  <span class="text-sm text-base-content/60">Loading…</span>
                </div>
              </:loading>
            </.svelte>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
