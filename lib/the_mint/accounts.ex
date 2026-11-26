defmodule TheMint.Accounts do
  @moduledoc "Accounts context – users and authentication."

  import Ecto.Query
  alias TheMint.Repo
  alias TheMint.Accounts.User

  def list_users, do: Repo.all(from u in User, order_by: [desc: u.role, asc: u.name, asc: u.id])

  def get_user(id), do: Repo.get(User, id)
  def get_user!(id), do: Repo.get!(User, id)
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def create_user(attrs), do: %User{} |> User.changeset(attrs) |> Repo.insert()

  def update_user(%User{} = user, attrs),
    do: user |> User.update_changeset(attrs) |> Repo.update()

  def change_user(%User{id: nil} = user, attrs \\ %{}), do: User.changeset(user, attrs)
  def change_user_for_edit(%User{} = user, attrs \\ %{}), do: User.update_changeset(user, attrs)

  def authenticate(email, password) do
    email = email |> to_string() |> String.trim() |> String.downcase()
    hash = :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)

    case Repo.get_by(User, email: email, password_hash: hash, is_active: true) do
      nil -> {:error, :invalid_credentials}
      user -> {:ok, user}
    end
  end
end
