defmodule Bumpr.Discord.BumpThread do
  use GenServer
  alias Bumpr.Thread

  def name(guild_id), do: :"#{__MODULE__}.#{guild_id}"

  def start_link(guild) do
    GenServer.start_link(__MODULE__, guild, name: name(guild.id))
  end

  def handle_message(message) do
    GenServer.call(name(message.guild_id), {:handle_message, message})
  end

  @impl GenServer
  def init(guild) do
    config = Thread.config(guild.id)
    parent = Thread.parent(guild.id)
    {:ok, %{config: config, parent: parent}}
  end

  @impl GenServer
  def handle_call(
        {:handle_message, %{channel_id: ch} = message},
        _from,
        %{config: %{channel_id: ch}} = state
      ) do
    author = Thread.get_author(message)

    if is_nil(author) do
      Thread.create_author(message)
    end

    parent = Thread.create_link(state.parent, message)
    {:reply, {:ok, state.parent}, %{state | parent: parent}}
  end

  def handle_call(_, _from, state) do
    {:reply, {:error, :wrong_channel}, state}
  end
end
