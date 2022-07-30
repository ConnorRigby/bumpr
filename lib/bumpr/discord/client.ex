defmodule Bumpr.Discord.Client do
  use Nostrum.Consumer

  require Logger

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    case Bumpr.Discord.BumpThread.handle_message(message) do
      {:ok, parent} ->
        if message.content == "bump", do: react(parent, message)
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
end
