defmodule TheMintWeb.PagesTest do
  use TheMintWeb.ConnCase

  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    {:ok, _} =
      TheMint.Accounts.create_user(%{
        email: "t@example.com",
        password: "secret123",
        role: "admin"
      })

    conn = post(conn, ~p"/login", %{"email" => "t@example.com", "password" => "secret123"})
    %{conn: recycle(conn)}
  end

  test "redirects to login when signed out" do
    assert redirected_to(get(build_conn(), ~p"/")) == ~p"/login"
  end

  test "all pages render", %{conn: conn} do
    for {path, text} <- [
          {~p"/", "Current sale"},
          {~p"/products", "Add product"},
          {~p"/sales", "No sales on this day."},
          {~p"/settings", "Sales split"}
        ] do
      {:ok, _lv, html} = live(conn, path)
      assert html =~ text
    end
  end
end
