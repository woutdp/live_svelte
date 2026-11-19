defmodule ExampleWeb.LiveSimpleCounterTest do
  use ExampleWeb.FeatureCase, async: true

  @moduledoc """
  E2E test for the LiveSimpleCounter LiveView with Svelte SimpleCounter components.
  Validates that the full stack (LiveView → LiveSvelte hook → Svelte) renders,
  that server increment updates the native counter and Svelte server props, and
  that server increments never reset or change either component's client state.
  """

  defp native_value(page), do: Page.get_by_test_id(page, "live-simple-counter-value")
  defp client_values(page), do: Page.get_by_test_id(page, "simple-counter-client-value")
  defp client_buttons(page), do: Page.get_by_test_id(page, "simple-counter-client-increment")

  defp click_native_increment(page) do
    Locator.click!(Page.get_by_test_id(page, "live-simple-counter-increment"))
  end

  defp assert_client_values_unchanged(page, expected_first, expected_second) do
    Expect.to_have_text!(client_values(page), [expected_first, expected_second])
  end

  defp click_client(page, index, times) do
    for n <- 1..times//1 do
      Locator.click!(Locator.nth(client_buttons(page), index))
      n
    end
  end

  test "page mounts and shows heading", %{page: page} do
    Page.goto!(page, "/live-simple-counter")

    Expect.to_be_visible!(Page.locator(page, "h1", has_text: "Simple Counter Demo"))
  end

  test "renders initial native counter and two SimpleCounter components", %{page: page} do
    Page.goto!(page, "/live-simple-counter")

    Expect.to_have_text!(native_value(page), "10")
    Expect.to_have_count!(Page.locator(page, "[data-name='SimpleCounter']"), 2)
  end

  test "clicking native +1 updates displayed number", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    click_native_increment(page)

    Expect.to_have_text!(native_value(page), "11")
  end

  test "increment updates server number in both Svelte components", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    click_native_increment(page)

    Expect.to_have_text!(
      Page.locator(page, "[data-name='SimpleCounter'] span.text-brand"),
      ["11", "11"]
    )
  end

  test "renders client counter at 1 in each SimpleCounter", %{page: page} do
    Page.goto!(page, "/live-simple-counter")

    Expect.to_have_text!(client_values(page), ["1", "1"])
  end

  test "clicking client +1 updates only that component's client counter", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_be_visible!(native_value(page))

    click_client(page, 0, 1)

    assert_client_values_unchanged(page, "2", "1")
  end

  test "client state survives a single server increment", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_text!(native_value(page), "10")

    click_client(page, 0, 1)
    assert_client_values_unchanged(page, "2", "1")

    click_native_increment(page)
    Expect.to_have_text!(native_value(page), "11")
    assert_client_values_unchanged(page, "2", "1")
  end

  test "client state survives multiple consecutive server increments", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_text!(native_value(page), "10")

    click_client(page, 0, 2)
    assert_client_values_unchanged(page, "3", "1")

    for n <- 11..13 do
      click_native_increment(page)
      Expect.to_have_text!(native_value(page), "#{n}")
      assert_client_values_unchanged(page, "3", "1")
    end
  end

  test "client state on second component only is unchanged by server increments", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_count!(client_values(page), 2)
    Expect.to_have_text!(native_value(page), "10")

    click_client(page, 1, 1)
    assert_client_values_unchanged(page, "1", "2")

    for n <- 11..12 do
      click_native_increment(page)
      Expect.to_have_text!(native_value(page), "#{n}")
      assert_client_values_unchanged(page, "1", "2")
    end
  end

  test "server increment never resets or changes client state on both components", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_count!(client_values(page), 2)
    Expect.to_have_text!(native_value(page), "10")

    click_client(page, 0, 3)
    click_client(page, 1, 4)
    assert_client_values_unchanged(page, "4", "5")

    for n <- 11..13 do
      click_native_increment(page)
      Expect.to_have_text!(native_value(page), "#{n}")
      assert_client_values_unchanged(page, "4", "5")
    end
  end

  test "server increments first, then client state: client state still unaffected by later server increments",
       %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_count!(client_values(page), 2)
    Expect.to_have_text!(native_value(page), "10")

    click_native_increment(page)
    Expect.to_have_text!(native_value(page), "11")
    click_native_increment(page)
    Expect.to_have_text!(native_value(page), "12")

    click_client(page, 0, 1)
    click_client(page, 1, 3)
    assert_client_values_unchanged(page, "2", "4")

    for n <- 13..14 do
      click_native_increment(page)
      Expect.to_have_text!(native_value(page), "#{n}")
      assert_client_values_unchanged(page, "2", "4")
    end
  end

  test "many server increments leave client state unchanged", %{page: page} do
    Page.goto!(page, "/live-simple-counter")
    Expect.to_have_count!(client_values(page), 2)
    Expect.to_have_text!(native_value(page), "10")

    click_client(page, 0, 1)
    assert_client_values_unchanged(page, "2", "1")

    for n <- 11..15 do
      click_native_increment(page)
      Expect.to_have_text!(native_value(page), "#{n}")
      assert_client_values_unchanged(page, "2", "1")
    end
  end
end
