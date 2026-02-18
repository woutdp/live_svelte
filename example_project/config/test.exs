import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :example, Example.Repo,
  database: Path.expand("../example_test#{System.get_env("MIX_TEST_PARTITION")}.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :example, ExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XvZC2gcAePazgtLhJ+/kX9NxRrJA9HBGVxRjfVHW7f//XBDiDpQJ4/ot6N3llQjW",
  server: true

# Wallaby E2E: base URL must match endpoint port
config :wallaby, base_url: "http://localhost:4002"

# PhoenixTest: lightweight server-side testing (no browser needed)
config :phoenix_test, :endpoint, ExampleWeb.Endpoint

# Disable LiveSvelte SSR in test so E2E tests run against the client-side bundle.
# Otherwise server-rendered HTML can mask client-only bugs (e.g. hardcoded props).
config :live_svelte, ssr: false

# In test we don't send emails.
config :example, Example.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
