defmodule LiveSvelte.EncoderTest do
  use ExUnit.Case, async: true

  require Protocol
  alias LiveSvelte.Encoder

  describe "encode/2 primitives" do
    test "Integer passes through" do
      assert Encoder.encode(42, []) == 42
    end

    test "Float passes through" do
      assert Encoder.encode(3.14, []) == 3.14
    end

    test "BitString passes through" do
      assert Encoder.encode("hello", []) == "hello"
    end

    test "Atom passes through" do
      assert Encoder.encode(:ok, []) == :ok
    end

    test "List recurses" do
      assert Encoder.encode([1, "a", :x], []) == [1, "a", :x]
      assert Encoder.encode([%{a: 1}], []) == [%{a: 1}]
    end

    test "Map recurses" do
      assert Encoder.encode(%{a: 1, b: "two"}, []) == %{a: 1, b: "two"}
    end
  end

  describe "encode/2 Date/Time ISO8601" do
    test "Date" do
      d = ~D[2026-01-31]
      assert Encoder.encode(d, []) == "2026-01-31"
    end

    test "Time" do
      t = ~T[14:30:00]
      assert Encoder.encode(t, []) == "14:30:00"
    end

    test "NaiveDateTime" do
      ndt = ~N[2026-01-31 14:30:00]
      assert Encoder.encode(ndt, []) == "2026-01-31T14:30:00"
    end

    test "DateTime" do
      dt = DateTime.from_naive!(~N[2026-01-31 14:30:00], "Etc/UTC")
      assert Encoder.encode(dt, []) == "2026-01-31T14:30:00Z"
    end
  end

  describe "@derive LiveSvelte.Encoder (default: all except __struct__)" do
    defmodule DeriveDefault do
      defstruct [:a, :b, :c]
    end

    Protocol.derive(Encoder, DeriveDefault)

    test "encodes all struct keys except __struct__" do
      s = %DeriveDefault{a: 1, b: "two", c: :three}
      assert Encoder.encode(s, []) == %{a: 1, b: "two", c: :three}
    end
  end

  describe "@derive {LiveSvelte.Encoder, only: keys}" do
    defmodule DeriveOnly do
      defstruct [:a, :b, :c]
    end

    Protocol.derive(Encoder, DeriveOnly, only: [:a, :c])

    test "encodes only specified keys" do
      s = %DeriveOnly{a: 1, b: "secret", c: 3}
      assert Encoder.encode(s, []) == %{a: 1, c: 3}
    end
  end

  describe "@derive {LiveSvelte.Encoder, except: keys}" do
    defmodule DeriveExcept do
      defstruct [:a, :b, :c]
    end

    Protocol.derive(Encoder, DeriveExcept, except: [:b])

    test "encodes all except specified keys" do
      s = %DeriveExcept{a: 1, b: "secret", c: 3}
      assert Encoder.encode(s, []) == %{a: 1, c: 3}
    end
  end

  describe "Phoenix.HTML.Form" do
    test "encodes name, values, errors, valid" do
      form = %Phoenix.HTML.Form{
        name: "user",
        source: %{},
        params: %{"name" => "alice", "email" => "a@b.com"},
        data: %{},
        hidden: %{},
        impl: Phoenix.HTML.FormData.Map,
        id: "user-form",
        errors: [name: {"can't be blank", []}],
        options: []
      }

      encoded = Encoder.encode(form, [])
      assert encoded.name == "user"
      assert encoded.valid == true
      assert encoded.values["name"] == "alice"
      assert encoded.values["email"] == "a@b.com"
      assert encoded.errors[:name] == ["can't be blank"]
    end
  end

  describe "Ecto.Changeset (when Ecto loaded)" do
    if Code.ensure_loaded?(Ecto) do
      defmodule EncoderTestUser do
        use Ecto.Schema

        schema "users" do
          field :name, :string
          field :email, :string
        end
      end

      test "encodes params, changes, errors, valid?" do
        cs =
          %EncoderTestUser{}
          |> Ecto.Changeset.cast(%{name: "alice", email: "a@b.com"}, [:name, :email])
          |> Ecto.Changeset.add_error(:name, "can't be blank")
          |> Ecto.Changeset.apply_action(:validate)

        case cs do
          {:ok, _} -> flunk("expected invalid changeset")
          {:error, changeset} ->
            encoded = Encoder.encode(changeset, [])
            assert encoded.valid? == false
            assert encoded.params["name"] == "alice"
            assert encoded.errors[:name] == ["can't be blank"]
        end
      end
    end
  end

  describe "nested structs" do
    defmodule Inner do
      defstruct [:x]
    end

    defmodule Outer do
      defstruct [:inner, :tag]
    end

    Protocol.derive(Encoder, Inner)
    Protocol.derive(Encoder, Outer)

    test "nested structs are encoded recursively" do
      s = %Outer{inner: %Inner{x: 42}, tag: "outer"}
      assert Encoder.encode(s, []) == %{inner: %{x: 42}, tag: "outer"}
    end
  end
end
