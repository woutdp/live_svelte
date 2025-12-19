defmodule LiveSvelte.SlotsTest do
  use ExUnit.Case, async: true

  alias LiveSvelte.Slots

  describe "filter_slots_from_assigns/1" do
    test "returns empty map when no slots present" do
      assigns = %{name: "Test", props: %{foo: "bar"}}
      assert Slots.filter_slots_from_assigns(assigns) == %{}
    end

    test "filters out slot entries from assigns" do
      slot_entry = %{__slot__: :button, inner_block: fn -> "content" end}
      assigns = %{
        name: "Test",
        button: [slot_entry],
        props: %{foo: "bar"}
      }

      result = Slots.filter_slots_from_assigns(assigns)

      assert Map.has_key?(result, :button)
      assert result[:button] == [slot_entry]
      refute Map.has_key?(result, :name)
      refute Map.has_key?(result, :props)
    end

    test "handles multiple slots" do
      button_slot = %{__slot__: :button, inner_block: fn -> "button" end}
      items_slot = %{__slot__: :items, inner_block: fn -> "items" end}

      assigns = %{
        name: "Test",
        button: [button_slot],
        items: [items_slot],
        props: %{}
      }

      result = Slots.filter_slots_from_assigns(assigns)

      assert Map.keys(result) |> Enum.sort() == [:button, :items]
    end

    test "handles slots with multiple entries" do
      slot1 = %{__slot__: :item, inner_block: fn -> "item1" end}
      slot2 = %{__slot__: :item, inner_block: fn -> "item2" end}

      assigns = %{
        item: [slot1, slot2],
        name: "Test"
      }

      result = Slots.filter_slots_from_assigns(assigns)

      assert result[:item] == [slot1, slot2]
    end

    test "ignores non-list values" do
      assigns = %{
        name: "Test",
        count: 5,
        active: true,
        data: %{nested: "value"}
      }

      assert Slots.filter_slots_from_assigns(assigns) == %{}
    end

    test "ignores lists without slot maps" do
      assigns = %{
        items: ["a", "b", "c"],
        numbers: [1, 2, 3],
        maps: [%{foo: "bar"}]
      }

      assert Slots.filter_slots_from_assigns(assigns) == %{}
    end
  end
end
