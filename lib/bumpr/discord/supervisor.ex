defmodule Bumpr.Discord.Supervisor do
  use DynamicSupervisor

  def start_child(guild) do
    DynamicSupervisor.start_child(__MODULE__, {Bumpr.Discord.BumpThread, guild})
  end

  def stop_child(_guild) do

  end

  @doc false
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
