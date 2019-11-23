defmodule BbddTest do
  use ExUnit.Case
  doctest Bbdd

  test "greets the world" do
    assert Bbdd.hello() == :world
  end
end
