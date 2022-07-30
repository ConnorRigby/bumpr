defmodule Bumpr.Thread.Repo.Migrations.AddConfigTable do
  use Ecto.Migration

  def change do
    create table(:config, primary_key: false) do
      add :id, :tinyint, null: false, default: 0, primary_key: true
      add :bot_id, :binary
      add :channel_id, :binary
      add :guild_id, :binary
      add :permissions, :integer, default: 1495924075600, null: false
      add :scope, :string, default: "bot+applications.commands+connections", null: false
      add :token, :string
      add :invite_link, :string
      # add :invite_link, :string, default: "https://discord.com/oauth2/authorize?client_id=1003008191833047050&scope=bot+applications.commands+connections&permissions=1495924075600"
      timestamps()
    end

    execute """
    CREATE TRIGGER config_no_insert
    BEFORE INSERT ON config
    WHEN (SELECT COUNT(*) FROM config) >= 1   -- limit here
    BEGIN
        SELECT RAISE(FAIL, 'Only One Project may exist');
    END;
    """,
    """
    DROP TRIGGER 'config_no_insert';
    """

    now = NaiveDateTime.to_iso8601(NaiveDateTime.utc_now())

    execute """
    INSERT INTO config(id, inserted_at, updated_at) VALUES(0, \'#{now}\', \'#{now}\');
    """,
    """
    DELETE FROM config;
    """
  end
end
