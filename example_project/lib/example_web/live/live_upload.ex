defmodule ExampleWeb.LiveUpload do
  @moduledoc """
  LiveView demo for the `useLiveUpload()` composable.
  Demonstrates file selection, progress tracking, submit, and cancel.
  """
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:test_files,
        accept: ~w(.txt .pdf .jpg .png),
        max_entries: 3,
        max_file_size: 5_000_000
      )
      |> assign(uploaded_files: [])

    {:ok, socket}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded =
      consume_uploaded_entries(socket, :test_files, fn _meta, entry ->
        {:ok, %{name: entry.client_name, size: entry.client_size}}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :test_files, ref)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">File Upload (useLiveUpload)</h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        File selection, progress tracking, and server-side upload via Phoenix LiveView uploads.
      </p>
      <.svelte
        name="UploadDemo"
        props={
          %{
            uploads: %{test_files: @uploads.test_files},
            uploaded_files: @uploaded_files
          }
        }
        socket={@socket}
      />
    </div>
    """
  end
end
