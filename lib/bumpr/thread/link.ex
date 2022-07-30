defmodule Bumpr.Thread.Link do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bumpr.Thread.{Config, Author}

  schema "links" do
    belongs_to :config, Config
    belongs_to :author, Author
    belongs_to :link, Bumpr.Thread.Link, foreign_key: :parent_id
    field :message_id, Snowflake
    field :content, :string
    timestamps()
  end

  def changeset(link, attrs \\ %{}) do
    link
    |> cast(attrs, [])
    |> validate_required([])
    |> unique_constraint(:parent_id)
    |> unique_constraint(:message_id)
  end
end
