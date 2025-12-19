defmodule LiveSvelte.ComponentsTest do
  use ExUnit.Case, async: true

  alias LiveSvelte.Slots

  describe "slot handling in generated components" do
    test "slots are properly identified and separated from props" do
      # Simulate assigns that would be passed to a generated component
      button_slot = %{__slot__: :button, inner_block: fn _, _ -> "button content" end}
      items_slot = %{__slot__: :items, inner_block: fn _, _ -> "items content" end}

      assigns = %{
        __changed__: nil,
        __given__: %{},
        ssr: true,
        class: "my-class",
        socket: nil,
        button: [button_slot],
        items: [items_slot],
        custom_prop: "value",
        another_prop: 123
      }

      # Extract slots
      slot_assigns = Slots.filter_slots_from_assigns(assigns)

      # Build props by filtering out reserved keys and slots
      props =
        assigns
        |> Map.drop([:__changed__, :__given__, :ssr, :class, :socket])
        |> Map.drop(Map.keys(slot_assigns))
        |> Enum.into(%{})

      # Verify slots were extracted
      assert Map.has_key?(slot_assigns, :button)
      assert Map.has_key?(slot_assigns, :items)

      # Verify props don't contain slots (which would cause JSON encoding errors)
      refute Map.has_key?(props, :button)
      refute Map.has_key?(props, :items)

      # Verify props contain the actual props
      assert props[:custom_prop] == "value"
      assert props[:another_prop] == 123

      # Verify props can be JSON encoded (slots contain functions which can't)
      assert {:ok, _} = Jason.encode(props)
    end

    test "slots with functions cannot be JSON encoded" do
      slot = %{__slot__: :test, inner_block: fn -> "content" end}

      # This is what was causing the original error
      assert_raise Protocol.UndefinedError, fn ->
        Jason.encode!(%{slot: [slot]})
      end
    end

    test "props without slots can be JSON encoded" do
      props = %{
        name: "TestComponent",
        count: 42,
        active: true,
        items: ["a", "b", "c"],
        nested: %{foo: "bar"}
      }

      assert {:ok, json} = Jason.encode(props)
      assert is_binary(json)
    end
  end
end
