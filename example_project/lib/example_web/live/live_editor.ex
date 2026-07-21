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
    <.demo_page title="Rich Editor (@attach)">
      <:description>
        Editor.js initialized via Svelte 5's <code class="font-mono">&#123;@attach&#125;</code>
        directive. Dynamic imports keep browser-only APIs out of the SSR bundle. Syncing will push editor content back to Phoenix LiveView.
      </:description>

      <.demo_card label="LiveSvelte">
        <.svelte name="RichEditor" props={%{initialContent: @content}} socket={@socket} />
      </.demo_card>

      <.demo_card label="Server state">
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
      </.demo_card>
    </.demo_page>
    """
  end
end
