defmodule ExampleWeb.PageControllerTest do
  use ExampleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "LiveSvelte Examples"
  end
end
