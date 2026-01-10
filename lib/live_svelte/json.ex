defmodule LiveSvelte.JSON do
  @moduledoc """
  JSON encoding using Erlang/OTP 27's native :json module.

  This module provides a Jason-compatible interface (`encode!/1`)
  that wraps the native Erlang :json module for use with LiveSvelte.

  ## Features

  - Uses Erlang's built-in `:json` module (OTP 27+)
  - Automatically converts structs to maps
  - Handles nested data structures

  ## Usage

  This module is the default JSON encoder for LiveSvelte. To use a different
  encoder like Jason, configure it in your `config.exs`:

      config :live_svelte, json_library: Jason

  """

  @doc """
  Encodes an Elixir term to a JSON string.

  Structs are automatically converted to maps before encoding.
  Returns a binary string.

  ## Examples

      iex> LiveSvelte.JSON.encode!(%{foo: "bar"})
      "{\"foo\":\"bar\"}"

      iex> LiveSvelte.JSON.encode!([1, 2, 3])
      "[1,2,3]"

  """
  @spec encode!(term()) :: binary()
  def encode!(term) do
    term
    |> prepare_term()
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  # Recursively prepare terms for JSON encoding.
  # Converts structs to maps, nil to null, and handles nested structures.

  defp prepare_term(nil), do: :null

  defp prepare_term(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> prepare_term()
  end

  defp prepare_term(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, prepare_term(v)} end)
  end

  defp prepare_term(list) when is_list(list) do
    Enum.map(list, &prepare_term/1)
  end

  defp prepare_term(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> prepare_term()
  end

  defp prepare_term(term), do: term
end
