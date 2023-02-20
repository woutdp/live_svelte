defmodule LiveSvelte.Logger do
  def log_info(status), do: Mix.shell().info([status, :reset])
  def log_success(status), do: Mix.shell().info([:green, status, :reset])
  def log_warning(status), do: Mix.shell().info([:yellow, status, :reset])
  def log_error(status), do: Mix.shell().error([status, :reset])
end
