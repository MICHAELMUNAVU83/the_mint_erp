defmodule TheMint.Sales.SaleItem do
  use Ecto.Schema

  schema "sale_items" do
    field :product_name, :string
    field :quantity, :integer
    field :unit_cost, :decimal
    field :unit_price, :decimal
    field :subtotal, :decimal

    belongs_to :sale, TheMint.Sales.Sale
    belongs_to :product, TheMint.Products.Product

    timestamps()
  end
end
