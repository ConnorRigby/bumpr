import Config

config :bumpr,  Bumpr.Thread.Repo, [
  priv: "priv/thread/repo",
  database: "bumpr_dev.db"
]

config :bumpr, ecto_repos: [Bumpr.Thread.Repo]
import_config "secret.exs"
