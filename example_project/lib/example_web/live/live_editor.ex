defmodule ExampleWeb.LiveEditor do
  use ExampleWeb, :live_view

  @initial_content %{
    "blocks" => [
      %{
        "type" => "header",
        "data" => %{"text" => "Welcome to the Rich Editor", "level" => 2}
      },
      %{
        "type" => "paragraph",
        "data" => %{
          "text" =>
            "This editor is initialized via Svelte 5's {@attach} directive. Edit this content and click \"Save to server\" to sync it back."
        }
      }
    ]
  }

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       content: @initial_content,
       block_count: length(@initial_content["blocks"]),
       last_save: nil
     )}
  end

  def handle_event("sync_content", %{"blocks" => blocks} = content, socket) do
    IO.inspect(blocks)
    {:noreply,
     assign(socket,
       content: content,
       block_count: length(blocks),
       last_save: DateTime.utc_now()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200/40 py-8 px-4">
      <div class="max-w-2xl mx-auto">
        <h1 class="text-center text-2xl font-light my-4">Rich Editor (@attach)</h1>
        <p class="text-sm text-base-content/50 mb-8 text-center">
          Editor.js initialized via Svelte 5's <code class="font-mono">&#123;@attach&#125;</code>
          directive. Dynamic imports keep browser-only APIs out of the SSR bundle. Syncing will push editor content back to Phoenix LiveView.
        </p>

        <div class="flex flex-col gap-8">
          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                LiveSvelte
              </span>
              <.svelte name="RichEditor" props={%{initialContent: @content}} socket={@socket} />
            </div>
          </section>

          <section class="card bg-base-100 shadow-lg border border-base-300/50">
            <div class="card-body gap-4">
              <span class="badge badge-outline badge-sm font-medium text-base-content/70 w-fit">
                Server state
              </span>
              <p class="text-sm text-base-content/70">
                Blocks saved: <strong data-testid="block-count">{@block_count}</strong>
              </p>
              <%= if @last_save do %>
                <p class="text-sm text-base-content/50">
                  Last saved at {Calendar.strftime(@last_save, "%H:%M:%S")} UTC
                </p>
              <% else %>
                <p data-testid="no-save-yet" class="text-sm text-base-content/40 italic">
                  No saves yet — edit the content above and click "Save to server".
                </p>
              <% end %>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
