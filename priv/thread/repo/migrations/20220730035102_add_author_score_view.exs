defmodule Bumpr.Thread.Repo.Migrations.AddAuthorScoreView do
  use Ecto.Migration

  def change do
    execute """
    CREATE TRIGGER link_content_check
    AFTER INSERT ON links
    WHEN (NEW.content != 'bump')
    BEGIN
      SELECT RAISE(ROLLBACK, 'content must be "bump"');
    END;
    """,
    """
    DROP TRIGGER 'link_content_check';
    """

    execute """
    CREATE TRIGGER link_score
    AFTER INSERT ON links
    WHEN (NEW.content = 'bump')
    BEGIN
      UPDATE authors SET score=score+1 WHERE id = NEW.author_id;
    END;
    """,
    """
    DROP TRIGGER 'link_score';
    """

    execute """
    CREATE VIEW leaderboard AS
      SELECT id, score, inserted_at, updated_at FROM authors ORDER BY score DESC;
    """,
    """
    DROP VIEW 'leaderboard'
    """
  end
end
