defmodule Bumpr.Thread.Leaderboard do
  use Ecto.Schema
  @primary_key false

  schema "leaderboard" do
    belongs_to :author, Bumpr.Thread.Author, foreign_key: :id, primary_key: true, type: Snowflake
    field :score, :integer
    field :discord_user, :map, virtual: true
    timestamps()
  end
end
