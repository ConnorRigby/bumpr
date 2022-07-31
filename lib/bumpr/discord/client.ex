defmodule Bumpr.Discord.Client do
  use Nostrum.Consumer

  require Logger

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def format_leaderboard(guild_id) do
    users = Bumpr.Thread.leaderboard(guild_id)
    |> Enum.map(fn %{id: author_id} = entry ->
      case get_user(author_id) do
        {:ok, data} ->
          %{entry | discord_user: data}
        _ -> entry
      end
    end)

    embed = Enum.reduce(users, %Nostrum.Struct.Embed{}, fn
      %{discord_user: %{} = user, score: score}, embed ->
        Nostrum.Struct.Embed.put_field(embed, "#{user.username}##{user.discriminator}", "#{score}")
      %{score: score, id: id}, embed ->
        Nostrum.Struct.Embed.put_field(embed, "unknown user #{id}", "#{score}")
    end)
    [first_user | _] = users
    [first | rest] = embed.fields
    %{embed | fields: [%{first | value: "#{first.value} 🏆"} | rest]}
    |> Nostrum.Struct.Embed.put_title("Current bump thread leaderboard")
    |> Nostrum.Struct.Embed.put_description("Leader: #{first.name}")
    |> Nostrum.Struct.Embed.put_thumbnail(Nostrum.Struct.User.avatar_url(first_user.discord_user))
  end

  def handle_event({:MESSAGE_CREATE, %{content: "leaderboard"} = message, _ws_state}) do
    embed = format_leaderboard(message.guild_id)
    Nostrum.Api.create_message(message.channel_id, embed: embed)
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    case Bumpr.Discord.BumpThread.handle_message(message) do
      {:ok, parent} ->
        react(parent, message)
      _ -> :ok
    end
  end

  def handle_event({:GUILD_DELETE, {guild, _}, _ws_state}) do
    Logger.info "GUILD_DELETE"
    Bumpr.Discord.Supervisor.stop_child(guild)
  end

  def handle_event({:GUILD_AVAILABLE, guild, _ws_state}) do
    Logger.info "GUILD_AVAILABLE"
    Bumpr.Thread.Repo.with_repo("guild.#{guild.id}.db", fn %{repo: repo, pid: pid} ->
      Ecto.Migrator.run(repo, :up,
      all: true,
      dynamic_repo: pid,
      log: :debug,
      log_migrations_sql: :debug,
      log_migrator_sql: :debug
    )
    end)
    Process.send_after(self(), :checkup, 5000)
    Bumpr.Discord.Supervisor.start_child(guild)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end

  def react(nil, message) do
    add_react(message)
  end

  def react(parent, message) do
    remove_react(message.channel_id, parent)
    add_react(message)
  end

  def remove_react(channel_id, parent) do
    case Nostrum.Api.delete_reaction(channel_id, parent.message_id, "🏆") do
      {:error, %{response: %{retry_after: retry}}} ->
        Process.sleep(round(retry))
        remove_react(channel_id, parent)
      {:ok} -> :ok
      error ->
        Logger.error %{remove_react: error}
    end
  end

  def add_react(message) do
    case Nostrum.Api.create_reaction(message.channel_id, message.id, "🏆") do
      {:error, %{response: %{retry_after: retry}}} ->
        Process.sleep(round(retry))
        add_react(message)
      {:ok} -> :ok

      error ->
        Logger.error %{add_react: error}
    end
  end

  def get_user(id) do
    case Nostrum.Api.get_user(id) do
      {:error, %{response: %{retry_after: retry}}} ->
        Process.sleep(round(retry))
        get_user(id)
      {:ok, user} -> {:ok, user}

      error ->
        Logger.error %{get_user: error}
    end
  end
end
