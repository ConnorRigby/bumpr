defmodule Bumpr.Thread.Repo.Migrations.AddAuthorScoreView do
  use Ecto.Migration

  def change do
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
