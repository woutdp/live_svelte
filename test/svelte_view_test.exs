defmodule LiveSvelteTest do
  use ExUnit.Case
  doctest LiveSvelte

  test "greets the world" do
    assert LiveSvelte.hello() == :world
  end
end
