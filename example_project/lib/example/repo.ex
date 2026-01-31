defmodule Example.Repo do
  use Ecto.Repo,
    otp_app: :example,
    adapter: Ecto.Adapters.SQLite3
end
