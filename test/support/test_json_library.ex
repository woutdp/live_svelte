defmodule TestJSONLibrary do
  @moduledoc false
  # Mock JSON library for testing custom configuration

  def encode!(data) do
    "TEST_ENCODED:#{inspect(data)}"
  end
end
