defmodule LiveSvelte.SSR.NodeJS do
  @moduledoc """
  Production SSR via elixir-nodejs.

  Loads the ESM bundle at `priv/svelte/server.mjs` using dynamic `import`, which
  avoids the memory leak caused by CommonJS `require` cache busting when
  `NODE_ENV` is unset. See [issue #133](https://github.com/woutdp/live_svelte/issues/133).
  """

  @behaviour LiveSvelte.SSR

  @default_ssr_filepath "./svelte/server.mjs"

  @doc """
  Sets `NODE_ENV` for Node.js SSR workers when `:ssr_node_env` is configured.

  Call this in `application.ex` before starting `NodeJS.Supervisor`. Node workers
  inherit the BEAM process environment.

      # config/prod.exs
      config :live_svelte, ssr_node_env: "production"

      # lib/my_app/application.ex
      def start(_type, _args) do
        LiveSvelte.SSR.NodeJS.setup_env!()
        ...
      end
  """
  @spec setup_env!() :: :ok
  def setup_env! do
    case Application.get_env(:live_svelte, :ssr_node_env) do
      nil ->
        :ok

      env when is_binary(env) ->
        if is_nil(System.get_env("NODE_ENV")) do
          System.put_env("NODE_ENV", env)
        end

        :ok
    end
  end

  @impl LiveSvelte.SSR
  def render(name, props, slots) do
    # Prepare props and slots for JSON serialization before passing to NodeJS.
    # This converts structs to maps, DateTime to ISO 8601 strings, and strips
    # Ecto metadata (__meta__). Required because NodeJS.call! uses Jason internally.
    prepared_props = LiveSvelte.JSON.prepare(props)
    prepared_slots = LiveSvelte.JSON.prepare(slots)
    filename = Application.get_env(:live_svelte, :ssr_filepath, @default_ssr_filepath)

    try do
      NodeJS.call!({filename, "render"}, [name, prepared_props, prepared_slots],
        binary: true,
        esm: true
      )
    catch
      :exit, {:noproc, _} ->
        message = """
        NodeJS is not configured. Please add the following to your application.ex:
        {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
        """

        raise %LiveSvelte.SSR.NotConfigured{message: message}
    end
  end

  @doc """
  Returns the `priv` directory used as `NODE_PATH` for elixir-nodejs workers.

  The SSR bundle path (`:ssr_filepath`, default `./svelte/server.mjs`) is resolved
  relative to this directory.
  """
  @spec server_path() :: String.t()
  def server_path do
    Application.app_dir(host_otp_app!(), "/priv")
  end

  defp host_otp_app! do
    case Application.get_env(:live_svelte, :otp_app) || infer_host_otp_app() do
      nil ->
        raise ArgumentError, """
        could not determine host OTP application for SSR.

        Configure it explicitly:

            config :live_svelte, otp_app: :my_app
        """

      app ->
        app
    end
  end

  defp infer_host_otp_app do
    case :application.get_application() do
      {:ok, app} -> app
      :undefined -> nil
    end
  end
end
