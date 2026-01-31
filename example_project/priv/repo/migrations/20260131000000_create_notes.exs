defmodule Example.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :content, :text
      add :color, :string, default: "#fef3c7"
      timestamps(type: :utc_datetime)
    end
  end
end
