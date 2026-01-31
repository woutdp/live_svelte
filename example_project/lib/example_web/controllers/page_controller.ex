defmodule ExampleWeb.PageController do
  use ExampleWeb, :controller


  def home(conn, _params) do
    render(conn, :home)
  end

  def hello_world(conn, _params), do: render(conn, :hello_world)
  def lodash(conn, _params), do: render(conn, :lodash)
  def plus_minus_svelte(conn, _params), do: render(conn, :plus_minus_svelte)
end
