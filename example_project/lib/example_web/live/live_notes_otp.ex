defmodule ExampleWeb.LiveNotesOtp do
  @moduledoc """
  LiveView demonstrating Ecto structs with OTP JSON encoder.

  The OTP JSON encoder (LiveSvelte.JSON) automatically converts Ecto structs
  to maps, stripping the __struct__ key. This means you can pass Ecto schemas
  directly to Svelte components without any additional configuration.

  This is the default encoder for LiveSvelte since v0.17.0.
  """
  use ExampleWeb, :live_view
  alias Example.Notes

  @info """
  Using OTP JSON encoder (default since v0.17.0). Ecto structs are automatically
  converted to maps.
  """

  def render(assigns) do
    ~H"""
    <.svelte
      name="NotesApp"
      props={%{
        notes: @notes,
        encoder: "OTP",
        info: @info
      }}
      socket={@socket}
    />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, notes: Notes.list_notes(), info: @info)}
  end

  def handle_event("create_note", params, socket) do
    case Notes.create_note(params) do
      {:ok, _note} ->
        {:noreply, assign(socket, :notes, Notes.list_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create note")}
    end
  end

  def handle_event("delete_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)

    case Notes.delete_note(note) do
      {:ok, _note} ->
        {:noreply, assign(socket, :notes, Notes.list_notes())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete note")}
    end
  end
end
