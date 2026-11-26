defmodule TheMint.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :string
    field :category, :string, default: "Other"
    field :buying_price, :decimal, default: Decimal.new(0)
    field :price, :decimal
    field :stock_quantity, :integer, default: 0
    field :is_active, :boolean, default: true

    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :category, :buying_price, :price, :stock_quantity, :is_active])
    |> validate_required([:name, :category, :buying_price, :price, :stock_quantity])
    |> update_change(:sku, &blank_to_nil/1)
    |> validate_number(:buying_price, greater_than_or_equal_to: 0)
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
    |> validate_price_above_cost()
    |> unique_constraint(:sku)
  end

  defp validate_price_above_cost(cs) do
    buy = get_field(cs, :buying_price)
    sell = get_field(cs, :price)

    if buy && sell && Decimal.lt?(sell, buy),
      do: add_error(cs, :price, "must not be below the buying price"),
      else: cs
  end

  defp blank_to_nil(s) do
    case String.trim(s) do
      "" -> nil
      t -> t
    end
  end
end
