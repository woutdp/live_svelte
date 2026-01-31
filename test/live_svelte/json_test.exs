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

  describe "prepare/1" do
    defmodule PrepareTestStruct do
      defstruct name: "test", count: 42
    end

    defmodule ListTestStruct do
      defstruct value: 0
    end

    test "converts DateTime to ISO 8601 string" do
      {:ok, dt, _} = DateTime.from_iso8601("2026-01-31T14:30:00Z")
      assert JSON.prepare(dt) == "2026-01-31T14:30:00Z"
    end

    test "converts NaiveDateTime to ISO 8601 string" do
      {:ok, ndt} = NaiveDateTime.new(2026, 1, 31, 14, 30, 0)
      assert JSON.prepare(ndt) == "2026-01-31T14:30:00"
    end

    test "converts Date to ISO 8601 string" do
      {:ok, date} = Date.new(2026, 1, 31)
      assert JSON.prepare(date) == "2026-01-31"
    end

    test "converts Time to ISO 8601 string" do
      {:ok, time} = Time.new(14, 30, 0)
      assert JSON.prepare(time) == "14:30:00"
    end

    test "converts DateTime with microseconds" do
      {:ok, dt, _} = DateTime.from_iso8601("2026-01-31T14:30:00.123456Z")
      assert JSON.prepare(dt) == "2026-01-31T14:30:00.123456Z"
    end

    test "converts nil to :null" do
      assert JSON.prepare(nil) == :null
    end

    test "preserves booleans" do
      assert JSON.prepare(true) == true
      assert JSON.prepare(false) == false
    end

    test "converts atoms to strings" do
      assert JSON.prepare(:hello) == "hello"
      assert JSON.prepare(:active) == "active"
    end

    test "converts struct to map with string keys" do
      result = JSON.prepare(%PrepareTestStruct{name: "hello", count: 10})
      assert result == %{"name" => "hello", "count" => 10}
    end

    test "converts nested maps with atom keys to string keys" do
      input = %{outer: %{inner: "value"}}
      assert JSON.prepare(input) == %{"outer" => %{"inner" => "value"}}
    end

    test "converts lists of structs" do
      input = [%ListTestStruct{value: 1}, %ListTestStruct{value: 2}]
      result = JSON.prepare(input)
      assert result == [%{"value" => 1}, %{"value" => 2}]
    end

    test "converts tuples to lists" do
      assert JSON.prepare({1, 2, 3}) == [1, 2, 3]
      assert JSON.prepare({"a", :b, 3}) == ["a", "b", 3]
    end

    test "handles nested DateTime in maps" do
      {:ok, dt, _} = DateTime.from_iso8601("2026-01-31T10:00:00Z")
      input = %{created_at: dt, name: "test"}
      result = JSON.prepare(input)
      assert result == %{"created_at" => "2026-01-31T10:00:00Z", "name" => "test"}
    end

    test "handles DateTime in lists" do
      {:ok, dt1, _} = DateTime.from_iso8601("2026-01-31T10:00:00Z")
      {:ok, dt2, _} = DateTime.from_iso8601("2026-01-31T11:00:00Z")
      input = [dt1, dt2]
      result = JSON.prepare(input)
      assert result == ["2026-01-31T10:00:00Z", "2026-01-31T11:00:00Z"]
    end

    test "handles deeply nested structures with dates" do
      {:ok, date} = Date.new(2026, 1, 31)

      input = %{
        user: %{
          profile: %{
            birthday: date,
            tags: [:admin, :active]
          }
        }
      }

      result = JSON.prepare(input)

      assert result == %{
               "user" => %{
                 "profile" => %{
                   "birthday" => "2026-01-31",
                   "tags" => ["admin", "active"]
                 }
               }
             }
    end
  end

  describe "prepare/1 with Ecto-like schemas" do
    # Simulates an Ecto schema struct with __meta__ field
    defmodule FakeEctoSchema do
      defstruct [:__meta__, :id, :title, :inserted_at]
    end

    defmodule FakeMeta do
      defstruct [:source, :state]
    end

    defmodule RegularStruct do
      defstruct [:name, :value]
    end

    test "strips __meta__ field from Ecto-like structs" do
      {:ok, dt, _} = DateTime.from_iso8601("2026-01-31T10:00:00Z")

      schema = %FakeEctoSchema{
        __meta__: %FakeMeta{source: "notes", state: :loaded},
        id: 1,
        title: "Hello",
        inserted_at: dt
      }

      result = JSON.prepare(schema)

      assert result == %{
               "id" => 1,
               "title" => "Hello",
               "inserted_at" => "2026-01-31T10:00:00Z"
             }

      refute Map.has_key?(result, "__meta__")
      refute Map.has_key?(result, :__meta__)
    end

    test "strips __meta__ from nested Ecto-like structs" do
      schema1 = %FakeEctoSchema{
        __meta__: %FakeMeta{source: "posts", state: :loaded},
        id: 1,
        title: "Post 1",
        inserted_at: nil
      }

      schema2 = %FakeEctoSchema{
        __meta__: %FakeMeta{source: "posts", state: :loaded},
        id: 2,
        title: "Post 2",
        inserted_at: nil
      }

      input = %{posts: [schema1, schema2]}
      result = JSON.prepare(input)

      assert result == %{
               "posts" => [
                 %{"id" => 1, "title" => "Post 1", "inserted_at" => :null},
                 %{"id" => 2, "title" => "Post 2", "inserted_at" => :null}
               ]
             }
    end

    test "handles regular structs without __meta__" do
      input = %RegularStruct{name: "test", value: 123}
      result = JSON.prepare(input)

      assert result == %{"name" => "test", "value" => 123}
    end
  end

  describe "encode!/1 with DateTime types" do
    defmodule EncodeEctoSchema do
      defstruct [:__meta__, :id, :name]
    end

    defmodule EncodeMeta do
      defstruct [:source]
    end

    test "encodes DateTime to ISO 8601 string in JSON" do
      {:ok, dt, _} = DateTime.from_iso8601("2026-01-31T14:30:00Z")
      result = JSON.encode!(%{timestamp: dt})
      decoded = :json.decode(result)
      assert decoded["timestamp"] == "2026-01-31T14:30:00Z"
    end

    test "encodes NaiveDateTime to ISO 8601 string in JSON" do
      {:ok, ndt} = NaiveDateTime.new(2026, 1, 31, 14, 30, 0)
      result = JSON.encode!(%{timestamp: ndt})
      decoded = :json.decode(result)
      assert decoded["timestamp"] == "2026-01-31T14:30:00"
    end

    test "encodes Date to ISO 8601 string in JSON" do
      {:ok, date} = Date.new(2026, 1, 31)
      result = JSON.encode!(%{date: date})
      decoded = :json.decode(result)
      assert decoded["date"] == "2026-01-31"
    end

    test "encodes Time to ISO 8601 string in JSON" do
      {:ok, time} = Time.new(14, 30, 0)
      result = JSON.encode!(%{time: time})
      decoded = :json.decode(result)
      assert decoded["time"] == "14:30:00"
    end

    test "encodes Ecto-like schema without __meta__ in JSON" do
      schema = %EncodeEctoSchema{
        __meta__: %EncodeMeta{source: "users"},
        id: 42,
        name: "Alice"
      }

      result = JSON.encode!(schema)
      decoded = :json.decode(result)

      assert decoded["id"] == 42
      assert decoded["name"] == "Alice"
      refute Map.has_key?(decoded, "__meta__")
    end
  end
end
