defmodule LiveSvelte.ReloadTest do
  # must be synchronous — tests are sensitive to config changes
  use ExUnit.Case, async: false

  setup do
    original = Application.get_env(:live_svelte, :vite_host)

    on_exit(fn ->
      if original == nil do
        Application.delete_env(:live_svelte, :vite_host)
      else
        Application.put_env(:live_svelte, :vite_host, original)
      end
    end)

    :ok
  end

  # Renders the vite_assets/1 function component to an HTML string.
  defp render(assets, inner_block_content) do
    assigns = %{
      __changed__: nil,
      assets: assets,
      inner_block: [%{inner_block: fn _, _ -> inner_block_content end}]
    }

    LiveSvelte.Reload.vite_assets(assigns)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  describe "vite_assets/1" do
    test "renders Vite dev server scripts when :vite_host is configured" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")

      html = render(["/js/app.js"], "fallback")

      assert html =~ ~s|src="http://localhost:5173/@vite/client"|
      assert html =~ ~s|src="http://localhost:5173/js/app.js"|
      assert html =~ ~s|type="module"|
      refute html =~ "fallback"
    end

    test "renders inner_block when :vite_host is not configured" do
      Application.delete_env(:live_svelte, :vite_host)

      html = render(["/js/app.js"], "FALLBACK_CONTENT")

      assert html =~ "FALLBACK_CONTENT"
      refute html =~ "@vite/client"
      refute html =~ "localhost:5173"
    end

    test "CSS assets render as link stylesheet tags" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")

      html = render(["/css/app.css"], "")

      assert html =~ ~s|rel="stylesheet"|
      assert html =~ "http://localhost:5173/css/app.css"
    end

    test "JS assets render as module script tags" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")

      html = render(["/js/app.js"], "")

      assert html =~ ~s|type="module"|
      assert html =~ "http://localhost:5173/js/app.js"
    end

    test "@vite/client script appears before other assets" do
      Application.put_env(:live_svelte, :vite_host, "http://localhost:5173")

      html = render(["/js/app.js"], "")

      {client_pos, _} = :binary.match(html, "@vite/client")
      {app_pos, _} = :binary.match(html, "/js/app.js")
      assert client_pos < app_pos
    end
  end
end
