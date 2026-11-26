defmodule TheMintWeb.UserAuth do
  @moduledoc """
  Session-based authentication. Works as both a Plug and a LiveView on_mount hook.
  """
  import Plug.Conn
  import Phoenix.Controller

  use Phoenix.VerifiedRoutes,
    endpoint: TheMintWeb.Endpoint,
    router: TheMintWeb.Router,
    statics: TheMintWeb.static_paths()

  alias TheMint.Accounts

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user, user_id && active_user(user_id))
  end

  def require_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Please sign in.")
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  def require_admin(conn, _opts) do
    if Accounts.User.admin?(conn.assigns[:current_user]) do
      conn
    else
      conn |> put_flash(:error, "Admins only.") |> redirect(to: ~p"/") |> halt()
    end
  end

  defp active_user(id) do
    case Accounts.get_user(id) do
      %{is_active: true} = u -> u
      _ -> nil
    end
  end

  def log_in_user(conn, user) do
    conn
    |> renew_session()
    |> put_session(:user_id, user.id)
    |> redirect(to: ~p"/")
  end

  def log_out_user(conn) do
    conn
    |> renew_session()
    |> redirect(to: ~p"/login")
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  def on_mount(:require_user, _params, session, socket) do
    socket =
      Phoenix.Component.assign_new(socket, :current_user, fn ->
        if user_id = session["user_id"], do: active_user(user_id)
      end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "Please sign in.")
       |> Phoenix.LiveView.redirect(to: ~p"/login")}
    end
  end

  def on_mount(:require_admin, _params, _session, socket) do
    if Accounts.User.admin?(socket.assigns[:current_user]) do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, "Admins only.")
       |> Phoenix.LiveView.redirect(to: ~p"/")}
    end
  end
end
