defmodule LiveSvelte.Logger do
  @moduledoc """
  Helper function for logging messages to the shell
  """

  @doc """
  Logs info messages to the shell
  """
  def log_info(status), do: Mix.shell().info([status, :reset])

  @doc """
  Logs success messages to the shell
  """
  def log_success(status), do: Mix.shell().info([:green, status, :reset])

  @doc """
  Logs warning messages to the shell
  """
  def log_warning(status), do: Mix.shell().info([:yellow, status, :reset])

  @doc """
  Logs error messages to the shell
  """
  def log_error(status), do: Mix.shell().error([status, :reset])
end
