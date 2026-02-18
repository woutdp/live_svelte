defmodule ExampleWeb.LiveClientSideLoadingTest do
  @moduledoc """
  E2E test for the LiveClientSideLoading LiveView (/live-client-side-loading).
  Validates that the page mounts, shows heading and description, and that both
  ClientSideLoading components hydrate and display content.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  defp wait_for_hydration(session, count, attempts \\ 30)
  defp wait_for_hydration(_session, _count, 0), do: :ok
  defp wait_for_hydration(session, count, attempts) do
    els = session |> all(Query.css("[data-testid='client-side-loading-content']"))
    if length(els) >= count do
      :ok
    else
      :timer.sleep(100)
      wait_for_hydration(session, count, attempts - 1)
    end
  end

  test "page mounts and shows heading", %{session: session} do
    session
    |> visit("/live-client-side-loading")
    |> find(Query.css("[data-testid='client-side-loading-heading']", text: "Client-side loading"))
  end

  test "renders description", %{session: session} do
    session
    |> visit("/live-client-side-loading")
    |> find(Query.css("p", text: "Use the loading slot when SSR is disabled; the slot shows until the component hydrates on the client."))
  end

  test "both components hydrate and show content", %{session: session} do
    session = visit(session, "/live-client-side-loading")
    session |> find(Query.css("[data-testid='client-side-loading-heading']"))

    wait_for_hydration(session, 2)

    content_els = session |> all(Query.css("[data-testid='client-side-loading-content']"))
    assert length(content_els) == 2,
           "expected 2 hydrated ClientSideLoading components, got #{length(content_els)}"

    for el <- content_els do
      assert Wallaby.Element.text(el) == "This is the component!"
    end
  end

  test "both sections show hydrated content after load", %{session: session} do
    session = visit(session, "/live-client-side-loading")
    wait_for_hydration(session, 2)

    session |> assert_has(Query.css("[data-testid='client-side-loading-client-section']"))
    session |> assert_has(Query.css("[data-testid='client-side-loading-server-section']"))

    content_els = session |> all(Query.css("[data-testid='client-side-loading-content']"))
    assert length(content_els) == 2
  end
end
