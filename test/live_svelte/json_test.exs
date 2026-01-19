defmodule LiveSvelte.JSONTest do
  use ExUnit.Case, async: true

  alias LiveSvelte.JSON

  describe "encode!/1" do
    test "encodes simple maps" do
      assert JSON.encode!(%{foo: "bar"}) == ~s({"foo":"bar"})
    end

    test "encodes nested maps" do
      result = JSON.encode!(%{outer: %{inner: "value"}})
      assert result == ~s({"outer":{"inner":"value"}})
    end

    test "encodes lists" do
      assert JSON.encode!([1, 2, 3]) == "[1,2,3]"
    end

    test "encodes lists of maps" do
      result = JSON.encode!([%{a: 1}, %{b: 2}])
      assert result == ~s([{"a":1},{"b":2}])
    end

    test "encodes integers" do
      assert JSON.encode!(42) == "42"
    end

    test "encodes floats" do
      assert JSON.encode!(3.14) == "3.14"
    end

    test "encodes booleans" do
      assert JSON.encode!(true) == "true"
      assert JSON.encode!(false) == "false"
    end

    test "encodes nil as null" do
      assert JSON.encode!(nil) == "null"
    end

    test "encodes strings" do
      assert JSON.encode!("hello") == ~s("hello")
    end

    test "encodes atoms as strings" do
      assert JSON.encode!(:hello) == ~s("hello")
    end

    test "encodes maps with atom keys" do
      result = JSON.encode!(%{foo: "bar", baz: 123})
      # Map key order may vary, so we parse and compare
      assert result =~ "foo"
      assert result =~ "bar"
      assert result =~ "baz"
      assert result =~ "123"
    end

    test "encodes maps with string keys" do
      assert JSON.encode!(%{"foo" => "bar"}) == ~s({"foo":"bar"})
    end
  end

  describe "struct encoding" do
    defmodule TestStruct do
      defstruct name: "test", value: 42
    end

    defmodule NestedStruct do
      defstruct user: nil, data: %{}
    end

    test "encodes structs as maps" do
      result = JSON.encode!(%TestStruct{})
      decoded = :json.decode(result)
      assert decoded["name"] == "test"
      assert decoded["value"] == 42
    end

    test "encodes structs with custom values" do
      result = JSON.encode!(%TestStruct{name: "custom", value: 100})
      decoded = :json.decode(result)
      assert decoded["name"] == "custom"
      assert decoded["value"] == 100
    end

    test "encodes nested structs" do
      nested = %NestedStruct{
        user: %TestStruct{name: "john", value: 30},
        data: %{key: "value"}
      }

      result = JSON.encode!(nested)
      decoded = :json.decode(result)
      assert decoded["user"]["name"] == "john"
      assert decoded["user"]["value"] == 30
      assert decoded["data"]["key"] == "value"
    end

    test "encodes structs in lists" do
      list = [%TestStruct{name: "a"}, %TestStruct{name: "b"}]
      result = JSON.encode!(list)
      decoded = :json.decode(result)
      assert length(decoded) == 2
      assert Enum.at(decoded, 0)["name"] == "a"
      assert Enum.at(decoded, 1)["name"] == "b"
    end
  end

  describe "tuple encoding" do
    test "encodes tuples as arrays" do
      assert JSON.encode!({1, 2, 3}) == "[1,2,3]"
    end

    test "encodes tuples with mixed types" do
      result = JSON.encode!({"hello", 42, true})
      assert result == ~s(["hello",42,true])
    end
  end

  describe "edge cases" do
    test "encodes empty map" do
      assert JSON.encode!(%{}) == "{}"
    end

    test "encodes empty list" do
      assert JSON.encode!([]) == "[]"
    end

    test "encodes deeply nested structures" do
      deep = %{a: %{b: %{c: %{d: [1, 2, %{e: "f"}]}}}}
      result = JSON.encode!(deep)
      decoded = :json.decode(result)
      assert get_in(decoded, ["a", "b", "c", "d"]) |> Enum.at(2) |> Map.get("e") == "f"
    end
  end

  describe "integer key handling" do
    test "encodes maps with integer keys as string keys" do
      result = JSON.encode!(%{1 => "a", 2 => "b"})
      decoded = :json.decode(result)
      assert Map.has_key?(decoded, "1")
      assert Map.has_key?(decoded, "2")
      assert decoded["1"] == "a"
      assert decoded["2"] == "b"
    end

    test "encodes large maps with integer keys (LiveJson scenario)" do
      data = for i <- 1..100, into: %{}, do: {i, i * 2}
      result = JSON.encode!(data)
      decoded = :json.decode(result)
      assert decoded["1"] == 2
      assert decoded["50"] == 100
      assert decoded["100"] == 200
    end

    test "encodes nested maps with integer keys" do
      data = %{1 => %{2 => "nested"}}
      result = JSON.encode!(data)
      decoded = :json.decode(result)
      assert decoded["1"]["2"] == "nested"
    end

    test "encodes mixed key types" do
      data = %{1 => "int", :atom => "atom", "string" => "string"}
      result = JSON.encode!(data)
      decoded = :json.decode(result)
      assert decoded["1"] == "int"
      assert decoded["atom"] == "atom"
      assert decoded["string"] == "string"
    end
  end

  describe "atom value handling" do
    test "encodes atom values as strings" do
      result = JSON.encode!(%{status: :active})
      decoded = :json.decode(result)
      assert decoded["status"] == "active"
    end

    test "preserves boolean atoms" do
      assert JSON.encode!(true) == "true"
      assert JSON.encode!(false) == "false"
    end

    test "encodes atom values in lists" do
      result = JSON.encode!([:one, :two, :three])
      assert result == ~s(["one","two","three"])
    end

    test "encodes mixed atom and string values" do
      result = JSON.encode!(%{atom_val: :test, string_val: "test"})
      decoded = :json.decode(result)
      assert decoded["atom_val"] == "test"
      assert decoded["string_val"] == "test"
    end
  end

  describe "float key handling" do
    test "encodes maps with float keys as string keys" do
      result = JSON.encode!(%{1.5 => "float"})
      decoded = :json.decode(result)
      # Float.to_string may produce different representations
      assert map_size(decoded) == 1
      assert Enum.at(Map.values(decoded), 0) == "float"
    end
  end
end
