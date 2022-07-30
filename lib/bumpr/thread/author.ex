defmodule Bumpr.Thread.Author do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bumpr.Thread.Link

  @primary_key false
  schema "authors" do
    field :id, Snowflake, primary_key: true
    has_many :link, Link, references: :id
    field :score, :integer, default: 0
    timestamps()
  end

  def changeset(author, attrs \\ %{}) do
    author
    |> cast(attrs, [:score])
    |> validate_required([:score])
    |> unique_constraint(:id)
  end
end
