defmodule LiveSvelte.Reload do
  @moduledoc """
  Utilities for easier integration with Vite in development.
  """
  use Phoenix.Component

  attr :assets, :list, required: true
  slot :inner_block, required: true, doc: "rendered when Vite path is not defined (production)"

  @doc """
  Renders Vite dev server assets in development, falls back to compiled assets in production.

  When `config :live_svelte, vite_host: "http://localhost:5173"` is set, injects:
  - `@vite/client` script (enables Vite HMR WebSocket)
  - CSS assets as `<link rel="stylesheet">` tags
  - JS assets as `<script type="module">` tags

  When `vite_host` is not configured, renders the `inner_block` unchanged.

  ## Example

      <LiveSvelte.Reload.vite_assets assets={["/js/app.js"]}>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </LiveSvelte.Reload.vite_assets>
  """
  def vite_assets(assigns) do
    vite_host = Application.get_env(:live_svelte, :vite_host)

    assigns =
      assigns
      |> assign(:vite_host, vite_host)
      |> assign(
        :stylesheets,
        for(path <- assigns.assets, String.ends_with?(path, ".css"), do: path)
      )
      |> assign(
        :javascripts,
        for(path <- assigns.assets, String.ends_with?(path, ".js"), do: path)
      )

    ~H"""
    <%= if @vite_host do %>
      <script type="module" src={"#{@vite_host}/@vite/client"}>
      </script>
      <link :for={path <- @stylesheets} rel="stylesheet" href={"#{@vite_host}#{path}"} />
      <script :for={path <- @javascripts} type="module" src={"#{@vite_host}#{path}"}>
      </script>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end
end
