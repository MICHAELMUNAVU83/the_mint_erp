defmodule TheMintWeb.ReceiptController do
  use TheMintWeb, :controller

  alias TheMint.Sales

  def show(conn, %{"id" => id}) do
    sale = Sales.get_sale_with_items!(id)

    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> render(:show, sale: sale, autoprint: conn.params["print"] != "0")
  end
end
