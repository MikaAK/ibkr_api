defmodule IbkrApiTest do
  use ExUnit.Case
  doctest IbkrApi

  test "greets the world" do
    assert IbkrApi.hello() == :world
  end
end
