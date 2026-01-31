defmodule LiveSvelte.JSON do
  @moduledoc """
  JSON encoding using Erlang/OTP 27's native :json module.

  This module provides a Jason-compatible interface (`encode!/1`)
  that wraps the native Erlang :json module for use with LiveSvelte.

  ## Features

  - Uses Erlang's built-in `:json` module (OTP 27+)
  - Automatically converts structs to maps
  - Converts all map keys to strings (matching Jason behavior)
  - Handles nested data structures
  - Converts DateTime/NaiveDateTime/Date/Time to ISO 8601 strings
  - Strips Ecto schema metadata (`__meta__` field) automatically

  ## Usage

  This module is the default JSON encoder for LiveSvelte. To use a different
  encoder like Jason, configure it in your `config.exs`:

      config :live_svelte, json_library: Jason

  ## SSR Compatibility Note

  When using server-side rendering, the NodeJS worker uses Jason internally
  to serialize data to the Node.js process. The `prepare/1` function is used
  to convert Elixir terms to JSON-compatible values before passing to NodeJS,
  ensuring consistency between SSR and client-side hydration.

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

  @doc """
  Prepares an Elixir term for JSON serialization.

  This function recursively converts Elixir terms to JSON-compatible values:
  - Structs become maps (with `__struct__` key stripped)
  - Ecto schemas have `__meta__` field stripped
  - DateTime/NaiveDateTime/Date/Time become ISO 8601 strings
  - Atoms become strings
  - nil becomes :null (for Erlang's :json module)

  This is useful for preparing data before passing to external JSON encoders
  (like the NodeJS worker which uses Jason internally).

  ## Examples

      iex> LiveSvelte.JSON.prepare(%DateTime{} = dt)
      "2026-01-31T20:31:10Z"

      iex> LiveSvelte.JSON.prepare(%{notes: [%MyApp.Note{title: "Hello"}]})
      %{"notes" => [%{"title" => "Hello"}]}

  """
  @spec prepare(term()) :: term()
  def prepare(term), do: prepare_term(term)

  # Recursively prepare terms for JSON encoding.
  # Converts structs to maps, nil to null, and handles nested structures.

  # nil becomes JSON null
  defp prepare_term(nil), do: :null

  # Booleans pass through (Erlang :json handles them)
  defp prepare_term(true), do: true
  defp prepare_term(false), do: false

  # Other atoms become strings (matches Jason behavior)
  defp prepare_term(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  # DateTime/NaiveDateTime/Date/Time become ISO 8601 strings
  # These must come before the generic struct handler
  defp prepare_term(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp prepare_term(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp prepare_term(%Date{} = d), do: Date.to_iso8601(d)
  defp prepare_term(%Time{} = t), do: Time.to_iso8601(t)

  # Ecto schema structs - strip __meta__ field
  # Must come before the generic struct handler
  defp prepare_term(%{__struct__: _, __meta__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> prepare_term()
  end

  # Structs become maps (strip __struct__ key)
  defp prepare_term(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> prepare_term()
  end

  # Maps: convert all keys to strings, recursively process values
  defp prepare_term(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {prepare_key(k), prepare_term(v)} end)
  end

  # Lists: recursively process elements
  defp prepare_term(list) when is_list(list) do
    Enum.map(list, &prepare_term/1)
  end

  # Tuples become arrays
  defp prepare_term(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> prepare_term()
  end

  # Numbers and binaries pass through
  defp prepare_term(term), do: term

  # Key conversion helpers - ensure all keys become strings
  defp prepare_key(key) when is_atom(key), do: Atom.to_string(key)
  defp prepare_key(key) when is_integer(key), do: Integer.to_string(key)
  defp prepare_key(key) when is_float(key), do: Float.to_string(key)
  defp prepare_key(key) when is_binary(key), do: key
  defp prepare_key(key), do: to_string(key)
end
