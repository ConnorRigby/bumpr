defmodule Bumpr.Thread.Repo.Migrations.AddAuthorsTable do
  use Ecto.Migration

  def change do
    create table(:authors, primary_key: false) do
      add :id, :string, primary_key: true
      add :score, :integer, default: 0, null: false
      timestamps()
    end
    create unique_index(:authors, :id)
  end
end
