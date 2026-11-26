defmodule TheMint.Repo.Migrations.AddCostsAndPaystackSplit do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :buying_price, :decimal, precision: 12, scale: 2, null: false, default: 0
    end

    alter table(:sale_items) do
      add :unit_cost, :decimal, precision: 12, scale: 2, null: false, default: 0
    end

    alter table(:sales) do
      add :status, :string, null: false, default: "paid"
      add :total_cost, :decimal, precision: 12, scale: 2, null: false, default: 0
      add :paystack_reference, :string
      # Snapshot of how the payment was split, in main currency units
      add :cost_account_code, :string
      add :cost_account_amount, :decimal, precision: 12, scale: 2
      add :profit_account_code, :string
      add :profit_account_amount, :decimal, precision: 12, scale: 2
      add :markup_percent, :decimal, precision: 6, scale: 2
    end

    create unique_index(:sales, [:paystack_reference])

    create table(:settings) do
      add :key, :string, null: false
      add :value, :text

      timestamps()
    end

    create unique_index(:settings, [:key])
  end
end
