defmodule Bumpr.Thread.Leaderboard do
  use Ecto.Schema
  @primary_key false

  schema "leaderboard" do
    belongs_to :author, Bumpr.Thread.Author, foreign_key: :id, primary_key: true, type: Snowflake
    field :score, :integer
    timestamps()
  end
end
