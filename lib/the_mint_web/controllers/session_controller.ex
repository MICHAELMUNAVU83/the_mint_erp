defmodule TheMintWeb.SessionController do
  use TheMintWeb, :controller

  alias TheMint.Accounts
  alias TheMintWeb.UserAuth

  def new(conn, _params) do
    if conn.assigns.current_user,
      do: redirect(conn, to: ~p"/"),
      else: render(conn, :new, error_message: nil, layout: false)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user)

      {:error, _} ->
        render(conn, :new, error_message: "Invalid email or password.", layout: false)
    end
  end

  def delete(conn, _params), do: UserAuth.log_out_user(conn)
end
