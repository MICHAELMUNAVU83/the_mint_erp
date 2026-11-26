defmodule TheMint.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :sku, :string
      add :price, :decimal, precision: 12, scale: 2, null: false
      add :stock_quantity, :integer, default: 0, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
