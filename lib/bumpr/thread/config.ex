defmodule Bumpr.Thread.Config do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bumpr.Thread.Link

  schema "config" do
    field :channel_id, Snowflake
    field :guild_id, Snowflake
    has_many :links, Link
    field :permissions, :integer, default: 1495924075600
  end

  def changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:guild_id, :channel_id])
    |> validate_required([:guild_id, :channel_id])
  end
end
