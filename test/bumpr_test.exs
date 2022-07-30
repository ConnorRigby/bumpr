defmodule BumprTest do
  use ExUnit.Case
  doctest Bumpr

  test "greets the world" do
    assert Bumpr.hello() == :world
  end
end
