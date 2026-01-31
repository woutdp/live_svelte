defmodule Example.Notes do
  @moduledoc """
  Context module for managing notes.
  """
  import Ecto.Query
  alias Example.Repo
  alias Example.Note

  @doc """
  Returns all notes ordered by creation date (newest first).
  """
  def list_notes do
    Note
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single note by ID.
  Raises `Ecto.NoResultsError` if the note does not exist.
  """
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Creates a new note.
  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing note.
  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a note.
  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns a changeset for tracking note changes.
  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end
end
