defmodule TheMintWeb.ReceiptHTML do
  use TheMintWeb, :html

  import TheMintWeb.Helpers, only: [fmt: 1]
  alias TheMint.Sales.Sale

  embed_templates "receipt_html/*"

  def change(%{payment_method: "cash", amount_paid: %Decimal{} = paid, total_amount: total}),
    do: Decimal.sub(paid, total)

  def change(_), do: nil
end
