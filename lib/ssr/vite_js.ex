defmodule LiveSvelte.SSR.ViteJS do
  @moduledoc """
  Implements SSR by making a POST request to `http://{:vite_host}/ssr_render`.

  `ssr_render` is implemented as a Vite plugin. Add it to the `vite.config.js` plugins section:

  ```javascript
  import liveSveltePlugin from "live_svelte/vitePlugin"

  export default {
    plugins: [liveSveltePlugin()],
    // ...
  }
  ```

  ## Configuration

  In `config/dev.exs`:

  ```elixir
  config :live_svelte, ssr_module: LiveSvelte.SSR.ViteJS
  config :live_svelte, vite_host: "http://localhost:5173"
  ```
  """
  @behaviour LiveSvelte.SSR

  def render(name, props, slots) do
    data = Jason.encode!(%{name: name, props: props, slots: slots})
    url = vite_path("/ssr_render")
    params = {String.to_charlist(url), [], ~c"application/json", data}

    case :httpc.request(:post, params, [], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        Jason.decode!(:erlang.list_to_binary(body))

      {:ok, {{_, 500, _}, _headers, body}} ->
        body_binary = :erlang.list_to_binary(body)

        message =
          case Jason.decode(body_binary) do
            {:ok, %{"error" => %{"message" => msg, "loc" => loc, "frame" => frame}}} ->
              "#{msg}\n#{loc["file"]}:#{loc["line"]}:#{loc["column"]}\n#{frame}"

            {:ok, %{"error" => %{"stack" => stack}}} ->
              stack

            _ ->
              "Unexpected Vite SSR response: 500 #{body_binary}"
          end

        raise %LiveSvelte.SSR.NotConfigured{message: message}

      {:ok, {{_, status, code}, _headers, _body}} ->
        raise %LiveSvelte.SSR.NotConfigured{
          message: "Unexpected Vite SSR response: #{status} #{:erlang.list_to_binary(code)}"
        }

      {:error, {:failed_connect, [{:to_address, {host, port}}, {_, _, code}]}} ->
        message = """
        Unable to connect to Vite #{host}:#{port}: #{code}

        Ensure Vite is running:
            cd assets && npx vite

        Or switch back to NodeJS SSR in config/dev.exs:
            config :live_svelte, ssr_module: LiveSvelte.SSR.NodeJS
        """

        raise %LiveSvelte.SSR.NotConfigured{message: message}

      {:error, reason} ->
        raise %LiveSvelte.SSR.NotConfigured{
          message: "ViteJS SSR connection error: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Returns a path relative to the configured Vite JS host.
  """
  def vite_path(path) do
    case Application.get_env(:live_svelte, :vite_host) do
      nil ->
        message = """
        Vite.js host is not configured. Please add the following to config/dev.exs:

        config :live_svelte, vite_host: "http://localhost:5173"

        and ensure Vite is running.
        """

        raise %LiveSvelte.SSR.NotConfigured{message: message}

      host ->
        Path.join(host, path)
    end
  end
end
