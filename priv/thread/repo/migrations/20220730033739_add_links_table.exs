defmodule Bumpr.Thread.Repo.Migrations.AddLinksTable do
  use Ecto.Migration

  def change do
    execute """
    CREATE TABLE links(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER,
      FOREIGN KEY(parent_id) REFERENCES links(id));
    ""","""
    DROP TABLE links;
    """
    alter table(:links, primary_key: false) do
      add :config_id, references("config"), null: false
      add :author_id, references("authors"), null: false
      add :message_id, :binary, null: false
      add :content, :binary, null: false
      timestamps()
    end
    create unique_index(:links, :parent_id)
    create unique_index(:links, :message_id)

    execute """
    CREATE TRIGGER link_has_parent
    AFTER INSERT ON links
    WHEN (select count(1) from links as l where l.parent_id is NULL) > 1   -- limit here
    BEGIN
        SELECT RAISE(ROLLBACK, 'Only One null link may exist');
    END;
    """,
    """
    DROP TRIGGER 'link_has_parent';
    """
  end
end
