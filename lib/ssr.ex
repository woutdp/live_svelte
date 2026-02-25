defmodule LiveSvelte.SSR.NotConfigured do
  @moduledoc false

  defexception [:message]
end

defmodule LiveSvelte.SSR do
  @moduledoc """
  A behaviour for rendering Svelte components server-side.

  To define a custom renderer, change the application config in `config.exs`:

      config :live_svelte, ssr_module: MyCustomSSRModule

  ## Telemetry

  Exposes a telemetry span for each render under the key `[:live_svelte, :ssr]`.

  The following events are emitted:

    * `[:live_svelte, :ssr, :start]` — fired when a render begins.
      Metadata: `%{component: name, props: props, slots: slots}`.

    * `[:live_svelte, :ssr, :stop]` — fired when a render completes successfully.
      Metadata: same. Measurements include `%{duration: duration}` in native time units
      (convert with `:erlang.convert_time_unit(duration, :native, :millisecond)`).

    * `[:live_svelte, :ssr, :exception]` — fired when the renderer raises.
      The exception is re-raised after the event is emitted.
  """

  @type component_name :: String.t()
  @type props :: %{optional(String.t() | atom) => any}
  @type slots :: %{optional(String.t() | atom) => any}

  @typedoc """
  A render response which should take the shape:
      %{
        "css" => %{
          "code" => String.t | nil,
          "map" => String.t | nil
        },
        "head" => String.t,
        "html" => String.t
      }
  """
  @type render_response :: %{
          required(String.t()) =>
            %{
              required(String.t()) => String.t() | nil
            }
            | String.t()
        }

  @callback render(component_name, props, slots) :: render_response | no_return

  @spec render(component_name, props, slots) :: render_response | no_return
  def render(name, props, slots) do
    mod = Application.get_env(:live_svelte, :ssr_module, LiveSvelte.SSR.NodeJS)
    meta = %{component: name, props: props, slots: slots}

    :telemetry.span([:live_svelte, :ssr], meta, fn ->
      {mod.render(name, props, slots), meta}
    end)
  end

  @deprecated "Use LiveSvelte.SSR.NodeJS.server_path/0 instead."
  def server_path() do
    LiveSvelte.SSR.NodeJS.server_path()
  end
end
