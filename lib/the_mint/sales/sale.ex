defmodule TheMint.Sales.Sale do
  use Ecto.Schema

  @payment_methods ~w(cash mpesa)

  schema "sales" do
    field :total_amount, :decimal
    field :total_cost, :decimal, default: Decimal.new(0)
    field :amount_paid, :decimal
    field :payment_method, :string, default: "cash"
    # paid | pending | cancelled
    field :status, :string, default: "paid"
    field :payment_reference, :string
    field :split_percent, :decimal
    field :cost_account_code, :string
    field :cost_account_amount, :decimal
    field :profit_account_code, :string
    field :profit_account_amount, :decimal

    belongs_to :user, TheMint.Accounts.User
    has_many :items, TheMint.Sales.SaleItem

    timestamps()
  end

  def payment_methods, do: @payment_methods

  def method_label("mpesa"), do: "M-Pesa"
  def method_label("card"), do: "Card"
  def method_label("paystack"), do: "Paystack"
  def method_label(_), do: "Cash"
end
