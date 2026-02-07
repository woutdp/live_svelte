defmodule ExampleWeb.LiveSigil do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~V"""
    <script>
      /** @type {{number: any}} */
      let { number } = $props();
      let number2 = $state(5);

      let combined = $derived(number + number2);
    </script>

    <div class="min-h-[50vh] flex flex-col justify-center items-center p-6 bg-base-200/40">
      <h1 class="text-2xl font-semibold text-base-content/80 mb-2 tracking-tight">
        Svelte template (~V sigil)
      </h1>
      <p class="text-sm text-base-content/50 mb-8 max-w-md text-center">
        Inline Svelte in LiveView: server state and client state in one template.
      </p>

      <div class="card bg-base-100 shadow-lg border border-base-300/50 w-full max-w-sm">
        <div class="card-body gap-4 p-6">
          <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
            Server + Client
          </span>
          <div class="font-mono text-center text-lg tabular-nums">
            <span class="text-brand">{number}</span>
            <span class="text-base-content/60"> + </span>
            <span class="text-success">{number2}</span>
            <span class="text-base-content/60"> = </span>
            <span class="font-bold text-brand">{combined}</span>
          </div>
          <div class="flex gap-2 justify-center pt-2">
            <button class="btn btn-sm bg-brand text-white border-0 hover:opacity-90" phx-click="increment">
              +server
            </button>
            <button class="btn btn-sm btn-success border-0" onclick={() => number2 += 1}>
              +client
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :number, 10)}
  end

  def handle_event("increment", _values, socket) do
    {:noreply, assign(socket, :number, socket.assigns.number + 1)}
  end
end
