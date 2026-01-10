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
end
