defmodule TheMint.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(cashier shot_girl sales_rep admin)

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :name, :string
    field :role, :string, default: "cashier"
    field :is_active, :boolean, default: true

    timestamps()
  end

  def roles, do: @roles
  def role_label("cashier"), do: "Cashier"
  def role_label("shot_girl"), do: "Shot Girl"
  def role_label("sales_rep"), do: "Sales Rep (Waitress)"
  def role_label("admin"), do: "Admin"
  def role_label(role), do: role

  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_), do: false

  @doc "New user: password required."
  def changeset(user, attrs) do
    user
    |> details(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
  end

  @doc "Edit user: password optional (blank keeps the current one)."
  def update_changeset(user, attrs) do
    attrs = if attrs["password"] in [nil, ""], do: Map.delete(attrs, "password"), else: attrs

    user
    |> details(attrs)
    |> cast(attrs, [:password])
    |> validate_password()
  end

  defp details(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :role, :is_active])
    |> update_change(:email, &(&1 |> String.trim() |> String.downcase()))
    |> validate_required([:email, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_inclusion(:role, @roles)
    |> unique_constraint(:email)
  end

  defp validate_password(cs) do
    cs
    |> validate_length(:password, min: 6)
    |> hash_password()
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    put_change(cs, :password_hash, :crypto.hash(:sha256, pw) |> Base.encode16(case: :lower))
  end

  defp hash_password(cs), do: cs
end
