defmodule TheMint.Repo.Migrations.RenameMarkupToSplitPercent do
  use Ecto.Migration

  def change do
    rename table(:sales), :markup_percent, to: :split_percent
  end
end
