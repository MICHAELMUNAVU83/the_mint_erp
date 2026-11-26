defmodule TheMint.Repo.Migrations.AddCategoryToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :category, :string, null: false, default: "Other"
    end

    create index(:products, [:category])
  end
end
