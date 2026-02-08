defmodule ExampleWeb.LiveNotesOtp do
  @moduledoc """
  LiveView demonstrating Ecto structs with OTP JSON encoder.

  The OTP JSON encoder (LiveSvelte.JSON) automatically converts Ecto structs
  to maps, stripping the __struct__ key. This means you can pass Ecto schemas
  directly to Svelte components without any additional configuration.

  This is the default encoder for LiveSvelte since v0.17.0.

  This LiveView also demonstrates real-time PubSub updates - when any user
  creates or deletes a note, all connected browsers see the change immediately.
  """
  use ExampleWeb, :live_view
  alias Example.Notes

  @topic "notes"
  @event_notes_updated "notes_updated"

  @info """
  Using OTP JSON encoder (default since v0.17.0). Ecto structs are automatically
  converted to maps. Changes sync across all browsers in real-time via PubSub.
  """

  def render(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center gap-6 p-6">
      <h2 class="text-center text-2xl font-light my-4">
        Notes (OTP)
      </h2>
      <p class="text-sm text-base-content/50 text-center max-w-md">
        Ecto structs are encoded automatically. Changes sync in real time across all browsers via PubSub.
      </p>
      <.svelte
        name="NotesApp"
        props={%{
          notes: @notes,
          encoder: "OTP",
          info: @info
        }}
        socket={@socket}
      />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      ExampleWeb.Endpoint.subscribe(@topic)
    end

    {:ok, assign(socket, notes: Notes.list_notes(), info: @info)}
  end

  def handle_event("create_note", params, socket) do
    case Notes.create_note(params) do
      {:ok, _note} ->
        broadcast_notes_updated()
        {:noreply, assign(socket, :notes, Notes.list_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create note")}
    end
  end

  def handle_event("delete_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)

    case Notes.delete_note(note) do
      {:ok, _note} ->
        broadcast_notes_updated()
        {:noreply, assign(socket, :notes, Notes.list_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete note")}
    end
  end

  # Handle PubSub broadcasts from other users
  def handle_info(%{topic: @topic, event: @event_notes_updated}, socket) do
    {:noreply, assign(socket, :notes, Notes.list_notes())}
  end

  defp broadcast_notes_updated do
    ExampleWeb.Endpoint.broadcast(@topic, @event_notes_updated, %{})
  end
end
