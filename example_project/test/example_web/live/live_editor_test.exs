defmodule ExampleWeb.LiveEditorTest do
  @moduledoc """
  E2E tests for the /live-editor LiveView with the RichEditor Svelte component.
  Validates the full pipeline: LiveView → LiveSvelte hook → Svelte mounts Editor.js via @attach.
  """
  use ExampleWeb.FeatureCase, async: false

  @moduletag :e2e

  test "page loads and shows heading", %{session: session} do
    session
    |> visit("/live-editor")
    |> assert_has(Query.css("h1", text: "Rich Editor (@attach)"))
  end

  test "editor container renders after Svelte mounts", %{session: session} do
    session = visit(session, "/live-editor")

    wait_for_editor(session)

    session |> assert_has(Query.css("[data-testid='editor-container']"))
  end

  test "save button is rendered by Svelte", %{session: session} do
    session = visit(session, "/live-editor")

    wait_for_editor(session)

    session |> assert_has(Query.css("[data-testid='editor-save-btn']"))
  end

  defp wait_for_editor(session, attempts \\ 50) do
    els = session |> all(Query.css("[data-testid='editor-container']"))

    cond do
      length(els) >= 1 ->
        :ok

      attempts == 0 ->
        raise "timeout waiting for editor-container to render"

      true ->
        :timer.sleep(100)
        wait_for_editor(session, attempts - 1)
    end
  end
end
