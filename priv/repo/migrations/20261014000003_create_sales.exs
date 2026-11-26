defmodule TheMint.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales) do
      add :total_amount, :decimal, precision: 12, scale: 2, null: false
      add :amount_paid, :decimal, precision: 12, scale: 2
      add :payment_method, :string, null: false, default: "cash"
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:sales, [:inserted_at])

    create table(:sale_items) do
      add :sale_id, references(:sales, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :nilify_all)
      add :product_name, :string, null: false
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 12, scale: 2, null: false
      add :subtotal, :decimal, precision: 12, scale: 2, null: false

      timestamps()
    end

    create index(:sale_items, [:sale_id])
  end
end
