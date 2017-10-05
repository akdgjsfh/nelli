defmodule NelliTest do
  use ExUnit.Case
  doctest Nelli

  test "greets the world" do
    assert Nelli.hello() == :world
  end
end
