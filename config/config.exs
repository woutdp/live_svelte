import Config

config :live_svelte,
  ssr_module: LiveSvelte.SSR.NodeJS,
  ssr: true

# json_library defaults to LiveSvelte.JSON (native Erlang :json module)
