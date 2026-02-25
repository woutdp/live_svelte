defmodule ExampleWeb.PhoenixTest.LiveCompositionTest do
  @moduledoc """
  PhoenixTest (in-process) for LiveComposition (/live-composition).
  Validates the page renders correctly, the initial data-props contract,
  and that `add-item` events update the items list sent to the component.
  """
  use ExampleWeb.ConnCase, async: false
  import PhoenixTest
  import Phoenix.LiveViewTest

  @moduletag :phoenix_test

  setup do
    ssr = Application.get_env(:live_svelte, :ssr, false)
    Application.put_env(:live_svelte, :ssr, true)
    on_exit(fn -> Application.put_env(:live_svelte, :ssr, ssr) end)
    :ok
  end

  test "renders heading and description", %{conn: conn} do
    conn
    |> visit("/live-composition")
    |> assert_has("h2", text: "Composition (useLiveSvelte)")
    |> assert_has("p", text: "useLiveSvelte()")
  end

  test "initial render passes empty items list in data-props", %{conn: conn} do
    conn
    |> visit("/live-composition")
    |> assert_has("[data-name='CompositionParent']")
    |> assert_has("[data-props*='\"items\":[]']")
  end

  test "add-item event prepends item to the list", %{conn: conn} do
    conn
    |> visit("/live-composition")
    |> unwrap(fn view -> render_click(view, "add-item", %{"name" => "Widget"}) end)
    |> assert_has("[data-props*='\"Widget\"']")
  end

  test "multiple add-item events accumulate in data-props", %{conn: conn} do
    conn
    |> visit("/live-composition")
    |> unwrap(fn view -> render_click(view, "add-item", %{"name" => "First"}) end)
    |> unwrap(fn view -> render_click(view, "add-item", %{"name" => "Second"}) end)
    |> assert_has("[data-props*='\"First\"']")
    |> assert_has("[data-props*='\"Second\"']")
  end
end
