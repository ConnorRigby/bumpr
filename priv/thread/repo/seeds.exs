alias Bumpr.Thread.{
  Repo, Link, Author
}
Repo.start_link()
config = Repo.one!(Config)
{:ok, author} = Repo.insert!(%Author{id: 1})
{:ok, link1} = Repo.insert!(%Link{author_id: author.id, config_id: config.id, message_id: 0, content: "hello"})
{:ok, link2} = Repo.insert!(%Link{author_id: author.id, config_id: config.id, message_id: 0, content: "hello"})
