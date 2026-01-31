defmodule Example.Note do
  @moduledoc """
  Ecto schema for notes with UUID primary key.

  This schema demonstrates how Ecto structs work with LiveSvelte's
  OTP JSON encoder, which automatically converts structs to maps.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notes" do
    field :title, :string
    field :content, :string
    field :color, :string, default: "#fef3c7"
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :content, :color])
    |> validate_required([:title])
    |> validate_length(:title, max: 100)
    |> validate_length(:content, max: 1000)
  end
end
