defmodule Bumpr.Thread.LinkTest do
  alias Bumpr.Thread.{
    Repo, Config, Author, Link, Leaderboard
  }

  use ExUnit.Case, async: true

  test "links chain" do
    config = Repo.one!(Config)
    author1 = Repo.insert!(%Author{id: 1})
    assert_raise Exqlite.Error, ~r/must be "bump"/, fn ->
      Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 1, content: "not bump"})
    end

    link1 = Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 1, content: "bump"})

    # message id
    assert_raise Ecto.ConstraintError, ~r/links_message_id_index/, fn ->
      Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 1, content: "bump"})
    end

    # only one nil parent
    assert_raise Exqlite.Error, ~r/Only One null link may exist/, fn ->
      Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 2, content: "bump"})
    end
    assert Enum.count(Repo.all(Link)) == 1

    link2 = Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 2, content: "bump", parent_id: link1.id})
    assert Enum.count(Repo.all(Link)) == 2

    assert_raise Ecto.ConstraintError, ~r/links_parent_id_index/, fn ->
      Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 3, content: "bump", parent_id: link1.id})
    end
    assert Enum.count(Repo.all(Link)) == 2

    assert Repo.reload!(author1).score == 2

    # score increases when `bump` is inserted
    link3 = Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 4, content: "bump", parent_id: link2.id})
    assert Repo.reload!(author1).score == 3
    link4 = Repo.insert!(%Link{author_id: author1.id, config_id: config.id, message_id: 5, content: "bump", parent_id: link3.id})
    assert Repo.reload!(author1).score == 4

    # leaderboard
    author2 = Repo.insert!(%Author{id: 2})
    link5 = Repo.insert!(%Link{author_id: author2.id, config_id: config.id, message_id: 6, content: "bump", parent_id: link4.id})
    author1 = Repo.reload!(author1)
    author2 = Repo.reload!(author2)
    assert author1.score == 4
    assert author2.score == 1
    leaderboard = Repo.all(Leaderboard)
    assert Enum.at(leaderboard, 0).id == author1.id
    assert Enum.at(leaderboard, 0).score == author1.score

    assert Enum.at(leaderboard, 1).id == author2.id
    assert Enum.at(leaderboard, 1).score == author2.score
  end
end
