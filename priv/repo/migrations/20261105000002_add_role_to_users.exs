defmodule TheMint.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :role, :string, null: false, default: "cashier"
    end

    flush()
    # Existing admin account(s) keep admin rights.
    execute "UPDATE users SET role = 'admin' WHERE email = 'admin@gmail.com' OR id = (SELECT min(id) FROM users)"
  end

  def down do
    alter table(:users) do
      remove :role
    end
  end
end
