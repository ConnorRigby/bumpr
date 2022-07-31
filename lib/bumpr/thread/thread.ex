defmodule Bumpr.Thread do
  import Ecto.Query, warn: false
  alias Bumpr.Thread.{
    Repo,
    Author,
    Link,
    Config,
    Leaderboard
  }, warn: false

  def leaderboard(guild_id) do
    Repo.with_repo(path(guild_id), fn %{repo: repo} ->
      repo.all(from l in Leaderboard)
      |> Enum.map(fn %{id: id} = entry ->
        author = repo.get(Author, id)
        %{entry | author: author}
      end)
    end)
  end

  def config(guild_id) do
    Repo.with_repo(path(guild_id), fn %{repo: repo} ->
      repo.one!(Config)
    end)
  end

  def parent(guild_id) do
    Repo.with_repo(path(guild_id), fn %{repo: repo} ->
      case repo.all(from l in Link, order_by: [desc: :id]) do
        [] -> nil
        [parent | _] -> parent
      end
    end)
  end

  def get_author(%{author: %{id: author_id}} = message) do
    Repo.with_repo(path(message.guild_id), fn %{repo: repo} ->
      repo.one(from a in Author, select: a.id, where: a.id == ^author_id)
    end)
  end

  def create_author(message) do
    Repo.with_repo(path(message.guild_id), fn %{repo: repo} ->
      repo.insert!(%Author{id: message.author.id})
    end)
  end

  def create_link(parent, message) do
    Repo.with_repo(path(message.guild_id), fn %{repo: repo} ->
      try do

        repo.insert(%Link{
          config_id: 0,
          author_id: message.author.id,
          parent_id: (parent || %{id: nil}).id,
          message_id: message.id,
          content: message.content
          })
        catch
          :error, %Exqlite.Error{} -> {:error, :invalid_bump}
          _error, exception when is_exception(exception) ->
            reraise(exception, __STACKTRACE__)
      end
    end)
  end

  def path(guild_id) do
    "guild.#{guild_id}.db"
  end
end
