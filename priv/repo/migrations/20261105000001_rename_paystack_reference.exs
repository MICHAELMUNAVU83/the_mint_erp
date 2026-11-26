defmodule TheMint.Repo.Migrations.RenamePaystackReference do
  use Ecto.Migration

  def change do
    rename table(:sales), :paystack_reference, to: :payment_reference
  end
end
