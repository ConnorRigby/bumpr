defmodule Bumpr.Discord.BumpThreadTest do
  use ExUnit.Case, async: true
  alias Bumpr.{Thread, Discord.BumpThread}

  test "handle_message" do
    guild_id = System.unique_integer([:positive])
    channel_id = System.unique_integer([:positive])

    Bumpr.Thread.Repo.with_repo("guild.#{guild_id}.db", fn %{repo: repo, pid: pid} ->
      Ecto.Migrator.run(repo, :up,
        all: true,
        dynamic_repo: pid,
        log: false,
        log_migrations_sql: false,
        log_migrator_sql: false
      )
    end)

    config = Thread.config(guild_id)

    changeset =
      Bumpr.Thread.Config.changeset(config, %{guild_id: guild_id, channel_id: channel_id})

    Bumpr.Thread.Repo.with_repo("guild.#{guild_id}.db", fn %{repo: repo, pid: pid} ->
      repo.update!(changeset)
    end)

    config = Thread.config(guild_id)

    {:ok, pid} = start_supervised({BumpThread, %{id: guild_id}})

    BumpThread.handle_message(%{
      id: 1,
      author: %{id: 1},
      content: "bump",
      guild_id: guild_id,
      channel_id: channel_id
    })

    BumpThread.handle_message(%{
      id: 2,
      author: %{id: 1},
      content: "bump",
      guild_id: guild_id,
      channel_id: channel_id
    })

    BumpThread.handle_message(%{
      id: 3,
      author: %{id: 2},
      content: "bump",
      guild_id: guild_id,
      channel_id: channel_id
    })

    leaderboard = Thread.leaderboard(guild_id)
    assert Enum.count(leaderboard) == 2
    assert Enum.at(leaderboard, 0).score == 2
    assert Enum.at(leaderboard, 1).score == 1
  end
end
