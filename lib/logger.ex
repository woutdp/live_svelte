defmodule LiveSvelte.Logger do
  @moduledoc false

  @doc false
  def log_info(status), do: Mix.shell().info([status, :reset])

  @doc false
  def log_success(status), do: Mix.shell().info([:green, status, :reset])

  @doc false
  def log_warning(status), do: Mix.shell().info([:yellow, status, :reset])

  @doc false
  def log_error(status), do: Mix.shell().error([status, :reset])
end
